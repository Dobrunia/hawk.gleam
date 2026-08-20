import gleam/option.{type Option}
import gleam/otp/actor
import transport
import typeid

pub type Message {
  SetUser(String)
  //   SetContext(String)
  //   CreateTransport(String)
}

pub type State {
  State(
    integration_token: String,
    user: String,
    context: Option(String),
    transport: transport.Transport,
  )
}

pub fn start_catcher_actor(integration_token: String, user: String) {
  let state = init_state(integration_token, user)

  let assert Ok(actor) =
    actor.new(state) |> actor.on_message(handle_message) |> actor.start
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

pub fn handle_message(
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
