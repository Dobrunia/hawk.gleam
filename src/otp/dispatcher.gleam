import event
import gleam/erlang/atom
import gleam/erlang/process.{type Name, type Subject}
import gleam/list
import gleam/otp/actor
import gleam/otp/factory_supervisor
import gleam/otp/supervision
import gleam/result
import otp/http_worker
import otp/protocol
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
  )
}

type State {
  State(
    integration_token: String,
    workers: List(Worker),
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
      let factory = factory_supervisor.get_by_name(worker_factory_name)

      use worker_1 <- result.try(start_worker(factory, 1, dispatcher))

      use worker_2 <- result.try(start_worker(factory, 2, dispatcher))

      let state =
        State(
          integration_token: integration_token,
          workers: [
            Worker(1, worker_1, Free),
            Worker(2, worker_2, Free),
          ],
          pending: [],
        )

      Ok(actor.initialised(state))
    })
    |> actor.named(name())
    |> actor.on_message(handle_message)
    |> actor.start
  })
}

fn start_worker(
  factory,
  id: Int,
  dispatcher: Subject(protocol.DispatcherMessage),
) -> Result(Subject(protocol.WorkerMessage), String) {
  case
    factory_supervisor.start_child(
      factory,
      http_worker.StartArgument(id, dispatcher),
    )
  {
    Ok(worker) -> Ok(worker.data)
    Error(_) -> Error("Failed to start HTTP worker")
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

fn handle_worker_online(
  state: State,
  worker_id: Int,
  worker_subject: Subject(protocol.WorkerMessage),
) -> actor.Next(State, protocol.DispatcherMessage) {
  let workers =
    state.workers
    |> list.map(fn(worker) {
      case worker.id == worker_id {
        True -> Worker(..worker, subject: worker_subject, status: Free)

        False -> worker
      }
    })

  actor.continue(State(..state, workers: workers))
}

fn handle_enqueue(
  state: State,
  payload: event.EventPayload,
) -> actor.Next(State, protocol.DispatcherMessage) {
  case
    event.create_new_and_valid_event(
      default_catcher_type,
      state.integration_token,
      payload,
    )
  {
    Error(error) -> {
      logger.log(error, logger.Error)
      actor.continue(state)
    }

    Ok(event) -> dispatch_event(state, event)
  }
}

fn handle_worker_ready(
  state: State,
  worker_id: Int,
) -> actor.Next(State, protocol.DispatcherMessage) {
  case state.pending {
    [] -> {
      let workers =
        state.workers
        |> list.map(fn(worker) {
          case worker.id == worker_id {
            True -> Worker(..worker, status: Free)
            False -> worker
          }
        })

      actor.continue(State(..state, workers: workers))
    }

    [next_event, ..rest] -> {
      case list.find(state.workers, fn(worker) { worker.id == worker_id }) {
        Error(_) -> actor.continue(state)

        Ok(worker) -> {
          actor.send(worker.subject, protocol.ProcessEvent(next_event))

          actor.continue(State(..state, pending: rest))
        }
      }
    }
  }
}

fn dispatch_event(
  state: State,
  event: event.Event,
) -> actor.Next(State, protocol.DispatcherMessage) {
  case list.find(state.workers, fn(worker) { worker.status == Free }) {
    Ok(worker) -> {
      actor.send(worker.subject, protocol.ProcessEvent(event))

      let workers =
        state.workers
        |> list.map(fn(current) {
          case current.id == worker.id {
            True -> Worker(..current, status: Busy)
            False -> current
          }
        })

      actor.continue(State(..state, workers: workers))
    }

    Error(_) -> {
      actor.continue(
        State(..state, pending: list.append(state.pending, [event])),
      )
    }
  }
}
