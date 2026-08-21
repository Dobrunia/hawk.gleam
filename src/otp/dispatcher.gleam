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

type WorkerStatus {
  Free
  Busy
}

type Worker {
  Worker(
    id: Int,
    subject: Subject(protocol.WorkerMessage),
    status: WorkerStatus,
    current: Option(event.Event),
  )
}

type Pending {
  Pending(next: List(event.Event), incoming: List(event.Event))
}

type State {
  State(
    integration_token: String,
    default_user: event.User,
    custom_transport: Option(String),
    workers: List(Worker),
    pending: Pending,
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
  transport: Option(String),
) {
  supervision.worker(fn() {
    actor.new_with_initialiser(5000, fn(dispatcher) {
      let restored = snapshot.load_or_init()
      let custom_transport = resolve_transport(transport, restored.transport)
      let http_transport = to_http_transport(custom_transport)
      let factory = factory_supervisor.get_by_name(worker_factory_name)

      use worker_1 <- result.try(start_worker(
        factory,
        1,
        dispatcher,
        http_transport,
      ))

      use worker_2 <- result.try(start_worker(
        factory,
        2,
        dispatcher,
        http_transport,
      ))

      let state =
        State(
          integration_token: integration_token,
          default_user: restored.default_user,
          custom_transport: custom_transport,
          workers: [
            Worker(1, worker_1, Free, option.None),
            Worker(2, worker_2, Free, option.None),
          ],
          pending: pending_from_list(list.append(
            restored.inflight,
            restored.pending,
          )),
        )

      let state = assign_pending(state)

      Ok(actor.initialised(state))
    })
    |> actor.named(name())
    |> actor.on_message(handle_message)
    |> actor.start
  })
}

fn resolve_transport(
  from_init: Option(String),
  from_snapshot: Option(String),
) -> Option(String) {
  case from_init {
    option.Some(url) -> option.Some(url)
    option.None -> from_snapshot
  }
}

fn to_http_transport(custom: Option(String)) -> transport.Transport {
  case custom {
    option.Some(url) -> transport.new(url)
    option.None -> transport.new("")
  }
}

fn start_worker(
  factory,
  id: Int,
  dispatcher: Subject(protocol.DispatcherMessage),
  worker_transport: transport.Transport,
) -> Result(Subject(protocol.WorkerMessage), String) {
  case
    factory_supervisor.start_child(
      factory,
      http_worker.StartArgument(id, dispatcher, worker_transport),
    )
  {
    Ok(worker) -> Ok(worker.data)
    Error(_) -> Error("Failed to start HTTP worker")
  }
}

fn pending_from_list(events: List(event.Event)) -> Pending {
  Pending(next: events, incoming: [])
}

fn pending_to_list(pending: Pending) -> List(event.Event) {
  list.append(pending.next, list.reverse(pending.incoming))
}

fn pending_push(pending: Pending, event: event.Event) -> Pending {
  Pending(..pending, incoming: [event, ..pending.incoming])
}

fn pending_pop(pending: Pending) -> Result(#(event.Event, Pending), Nil) {
  case pending.next {
    [event, ..rest] -> Ok(#(event, Pending(..pending, next: rest)))

    [] ->
      case list.reverse(pending.incoming) {
        [] -> Error(Nil)
        [event, ..rest] -> Ok(#(event, Pending(next: rest, incoming: [])))
      }
  }
}

fn inflight_events(workers: List(Worker)) -> List(event.Event) {
  list.filter_map(workers, fn(worker) {
    case worker.current {
      option.Some(event) -> Ok(event)
      option.None -> Error(Nil)
    }
  })
}

fn durable(state: State) -> snapshot.Snapshot {
  snapshot.Snapshot(
    default_user: state.default_user,
    pending: pending_to_list(state.pending),
    inflight: inflight_events(state.workers),
    transport: state.custom_transport,
  )
}

/// Persist first, then send. Crash after persist + before send → replay.
fn commit(state: State) -> State {
  snapshot.save(durable(state))
  state
}

fn set_current(
  workers: List(Worker),
  worker_id: Int,
  status: WorkerStatus,
  current: Option(event.Event),
) -> List(Worker) {
  list.map(workers, fn(worker) {
    case worker.id == worker_id {
      True -> Worker(..worker, status: status, current: current)
      False -> worker
    }
  })
}

fn assign_pending(state: State) -> State {
  case list.find(state.workers, fn(worker) { worker.status == Free }) {
    Error(_) -> state

    Ok(worker) ->
      case pending_pop(state.pending) {
        Error(_) -> commit(state)

        Ok(#(event, rest)) -> {
          let state =
            State(
              ..state,
              pending: rest,
              workers: set_current(
                state.workers,
                worker.id,
                Busy,
                option.Some(event),
              ),
            )
            |> commit

          actor.send(worker.subject, protocol.ProcessEvent(event))
          assign_pending(state)
        }
      }
  }
}

fn handle_message(
  state: State,
  message: protocol.DispatcherMessage,
) -> actor.Next(State, protocol.DispatcherMessage) {
  case message {
    protocol.Enqueue(payload) -> handle_enqueue(state, payload)

    protocol.WorkerReady(worker_id) -> handle_worker_ready(state, worker_id)

    protocol.WorkerOnline(worker_id, worker_subject) ->
      handle_worker_online(state, worker_id, worker_subject)
  }
}

fn same_owner(
  left: Subject(protocol.WorkerMessage),
  right: Subject(protocol.WorkerMessage),
) -> Bool {
  process.subject_owner(left) == process.subject_owner(right)
}

fn handle_worker_online(
  state: State,
  worker_id: Int,
  worker_subject: Subject(protocol.WorkerMessage),
) -> actor.Next(State, protocol.DispatcherMessage) {
  let workers =
    list.map(state.workers, fn(worker) {
      case worker.id == worker_id {
        False -> worker

        True ->
          case same_owner(worker.subject, worker_subject) {
            True -> Worker(..worker, subject: worker_subject)

            False ->
              case worker.current {
                option.Some(event) -> {
                  actor.send(worker_subject, protocol.ProcessEvent(event))
                  Worker(
                    ..worker,
                    subject: worker_subject,
                    status: Busy,
                    current: option.Some(event),
                  )
                }

                option.None ->
                  Worker(
                    ..worker,
                    subject: worker_subject,
                    status: Free,
                    current: option.None,
                  )
              }
          }
      }
    })

  actor.continue(State(..state, workers: workers))
}

fn handle_enqueue(
  state: State,
  payload: event.EventPayload,
) -> actor.Next(State, protocol.DispatcherMessage) {
  let payload = event.apply_default_user(payload, state.default_user)

  case
    event.create_new_and_valid_event(
      default_catcher_type,
      state.integration_token,
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

fn handle_worker_ready(
  state: State,
  worker_id: Int,
) -> actor.Next(State, protocol.DispatcherMessage) {
  let workers = set_current(state.workers, worker_id, Free, option.None)

  actor.continue(assign_pending(State(..state, workers: workers)))
}

fn dispatch_event(state: State, event: event.Event) -> State {
  assign_pending(State(..state, pending: pending_push(state.pending, event)))
}
