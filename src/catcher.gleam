import gleam/option.{type Option}
import gleam/otp/actor
import transport
import typeid

pub type Message {
  SetUser(String)
  //   SetContext(String)
  //   CreateTransport(String)
  //   SendEvent(Event)
}

type State {
  State(
    integration_token: String,
    user: String,
    context: Option(String),
    transport: transport.Transport,
  )
}

pub fn start_catcher_actor(
  integration_token: String,
  user: String,
) -> Result(Nil, String) {
  let state = init_state(integration_token, user)

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

fn resolve_user(user: String) -> String {
  case user {
    "" -> generate_user()
    _ -> user
  }
}

fn init_state(integration_token: String, user: String) -> State {
  State(integration_token, resolve_user(user), option.None, transport.new(""))
}

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    SetUser(user) -> {
      let state = State(..state, user: resolve_user(user))
      actor.continue(state)
    }
  }
}
