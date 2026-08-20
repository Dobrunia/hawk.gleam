import gleam/option.{type Option}
import gleam/otp/actor
import transport
import typeid

pub type Message

//   SendEvent(Event)

type State {
  State(
    integration_token: String,
    user: String,
    context: Option(String),
    transport: transport.Transport,
  )
}

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
    _ -> actor.continue(state)
  }
}
