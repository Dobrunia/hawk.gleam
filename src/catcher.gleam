import event
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import transport
import typeid

type Message {
  SendEvent(
    payload: event.EventPayload,
    reply_with: Subject(Result(Nil, String)),
  )
}

type State {
  State(
    integration_token: String,
    user: String,
    context: Option(String),
    transport: transport.Transport,
  )
}

const default_catcher_type = "errors/default"

pub fn start_catcher_actor(integration_token: String) -> Result(Nil, String) {
  let state =
    State(integration_token, generate_user(), option.None, transport.new(""))

  case
    actor.new(state)
    |> actor.on_message(handle_message)
    |> actor.start
  {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error("Failed to start Hawk catcher")
  }
}

fn generate_user() -> String {
  let assert Ok(id) = typeid.new("user")
  typeid.to_string(id)
}

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    SendEvent(payload, reply_with) -> {
      case
        event.create_new_and_valid_event(
          default_catcher_type,
          state.integration_token,
          payload,
        )
      {
        Error(error) -> {
          actor.send(reply_with, Error(error))
        }

        Ok(event) -> {
          let result = transport.send(state.transport, event)
          actor.send(reply_with, result)
        }
      }
      actor.continue(state)
    }
  }
}
