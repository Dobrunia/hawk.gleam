import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import otp/protocol
import transport
import utils/logger

pub type StartArgument {
  StartArgument(
    id: Int,
    dispatcher: Subject(protocol.DispatcherMessage),
    transport: transport.Transport,
  )
}

type State {
  State(
    id: Int,
    dispatcher: Subject(protocol.DispatcherMessage),
    transport: transport.Transport,
  )
}

@internal
pub fn start(argument: StartArgument) {
  let state =
    State(
      id: argument.id,
      dispatcher: argument.dispatcher,
      transport: argument.transport,
    )

  case
    actor.new(state)
    |> actor.on_message(handle_message)
    |> actor.start
  {
    Ok(started) -> {
      actor.send(
        argument.dispatcher,
        protocol.WorkerOnline(argument.id, started.data),
      )

      Ok(started)
    }

    Error(error) -> Error(error)
  }
}

fn handle_message(
  state: State,
  message: protocol.WorkerMessage,
) -> actor.Next(State, protocol.WorkerMessage) {
  case message {
    protocol.ProcessEvent(event) -> {
      case transport.send(state.transport, event) {
        Ok(_) -> Nil

        Error(error) -> logger.event_not_sent(error)
      }

      actor.send(state.dispatcher, protocol.WorkerReady(state.id))

      actor.continue(state)
    }
  }
}
