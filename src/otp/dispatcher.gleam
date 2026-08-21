import event
import gleam/erlang/atom
import gleam/erlang/process.{type Name, type Subject}
import gleam/list
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/otp/factory_supervisor
import gleam/otp/supervision
import gleam/result
import otp/http_worker
import otp/protocol
import otp/snapshot
import transport
import utils/logger

const default_catcher_type = "errors/default"

const max_pending_events = 100

type WorkerStatus {
  Free
  Busy
}

type Worker {
  Worker(
    subject: Subject(protocol.WorkerMessage),
    status: WorkerStatus,
    current: Option(event.Event),
  )
}

type State {
  State(
    integration_token: String,
    default_user: event.User,
    transport: transport.Transport,
    worker: Worker,
    pending: List(event.Event),
  )
}

@external(erlang, "gleam_erlang_ffi", "identity")
fn atom_to_name(atom: atom.Atom) -> Name(protocol.DispatcherMessage)

fn name() -> Name(protocol.DispatcherMessage) {
  atom.create("hawk_gleam_dispatcher")
  |> atom_to_name
}

@internal
pub fn is_running() -> Bool {
  case process.named(name()) {
    Ok(_) -> True
    Error(_) -> False
  }
}

@internal
pub fn enqueue(payload: event.EventPayload) -> Result(Nil, String) {
  case process.named(name()) {
    Error(_) -> Error("Hawk is not initialized")
    Ok(_) -> {
      actor.send(process.named_subject(name()), protocol.Enqueue(payload))
      Ok(Nil)
    }
  }
}

@internal
pub fn supervised(
  integration_token: String,
  worker_factory_name: Name(
    factory_supervisor.Message(
      http_worker.StartArgument,
      Subject(protocol.WorkerMessage),
    ),
  ),
) {
  supervision.worker(fn() {
    actor.new_with_initialiser(5000, fn(dispatcher) {
      let restored = snapshot.load_or_init()
      let factory = factory_supervisor.get_by_name(worker_factory_name)

      use worker_subject <- result.try(start_worker(
        factory,
        dispatcher,
        restored.transport,
      ))

      let state =
        State(
          integration_token: integration_token,
          default_user: restored.default_user,
          transport: restored.transport,
          worker: Worker(worker_subject, Free, option.None),
          pending: list.append(restored.inflight, restored.pending),
        )
        |> assign_pending

      Ok(actor.initialised(state))
    })
    |> actor.named(name())
    |> actor.on_message(handle_message)
    |> actor.start
  })
}

fn start_worker(
  factory,
  dispatcher: Subject(protocol.DispatcherMessage),
  worker_transport: transport.Transport,
) -> Result(Subject(protocol.WorkerMessage), String) {
  case
    factory_supervisor.start_child(
      factory,
      http_worker.StartArgument(dispatcher, worker_transport),
    )
  {
    Ok(worker) -> Ok(worker.data)
    Error(_) -> Error("Failed to start HTTP worker")
  }
}

fn durable(state: State) -> snapshot.Snapshot {
  let inflight = case state.worker.current {
    option.Some(event) -> [event]
    option.None -> []
  }

  snapshot.Snapshot(
    default_user: state.default_user,
    pending: state.pending,
    inflight: inflight,
    transport: state.transport,
  )
}

fn commit(state: State) -> State {
  snapshot.save(durable(state))
  state
}

fn assign_pending(state: State) -> State {
  case state.worker.status, state.pending {
    Busy, _ -> state
    Free, [] -> commit(state)
    Free, [event, ..rest] -> {
      let state =
        State(
          ..state,
          worker: Worker(
            ..state.worker,
            status: Busy,
            current: option.Some(event),
          ),
          pending: rest,
        )
        |> commit

      actor.send(state.worker.subject, protocol.ProcessEvent(event))
      state
    }
  }
}

fn handle_message(
  state: State,
  message: protocol.DispatcherMessage,
) -> actor.Next(State, protocol.DispatcherMessage) {
  case message {
    protocol.Enqueue(payload) -> handle_enqueue(state, payload)
    protocol.WorkerReady -> handle_worker_ready(state)
    protocol.WorkerOnline(worker_subject) ->
      handle_worker_online(state, worker_subject)
  }
}

fn handle_enqueue(
  state: State,
  payload: event.EventPayload,
) -> actor.Next(State, protocol.DispatcherMessage) {
  case
    event.create_new_and_valid_event(
      default_catcher_type,
      state.integration_token,
      state.default_user,
      payload,
    )
  {
    Error(error) -> {
      logger.event_not_sent(error)
      actor.continue(state)
    }
    Ok(event) -> actor.continue(dispatch_event(state, event))
  }
}

fn dispatch_event(state: State, event: event.Event) -> State {
  case state.worker.status {
    Free -> {
      let state =
        State(
          ..state,
          worker: Worker(
            ..state.worker,
            status: Busy,
            current: option.Some(event),
          ),
        )
        |> commit

      actor.send(state.worker.subject, protocol.ProcessEvent(event))
      state
    }

    Busy ->
      case list.length(state.pending) >= max_pending_events {
        True -> {
          logger.event_not_sent("Pending queue capacity exceeded")
          state
        }
        False ->
          State(..state, pending: list.append(state.pending, [event]))
          |> commit
      }
  }
}

fn handle_worker_ready(
  state: State,
) -> actor.Next(State, protocol.DispatcherMessage) {
  let state =
    State(
      ..state,
      worker: Worker(..state.worker, status: Free, current: option.None),
    )
    |> assign_pending

  actor.continue(state)
}

fn same_owner(
  left: Subject(protocol.WorkerMessage),
  right: Subject(protocol.WorkerMessage),
) -> Bool {
  process.subject_owner(left) == process.subject_owner(right)
}

fn handle_worker_online(
  state: State,
  worker_subject: Subject(protocol.WorkerMessage),
) -> actor.Next(State, protocol.DispatcherMessage) {
  case same_owner(state.worker.subject, worker_subject) {
    True ->
      actor.continue(
        State(..state, worker: Worker(..state.worker, subject: worker_subject)),
      )

    False ->
      case state.worker.current {
        option.Some(event) -> {
          actor.send(worker_subject, protocol.ProcessEvent(event))
          actor.continue(
            State(
              ..state,
              worker: Worker(
                subject: worker_subject,
                status: Busy,
                current: option.Some(event),
              ),
            ),
          )
        }

        option.None -> {
          let state =
            State(
              ..state,
              worker: Worker(
                subject: worker_subject,
                status: Free,
                current: option.None,
              ),
            )
            |> assign_pending
          actor.continue(state)
        }
      }
  }
}
