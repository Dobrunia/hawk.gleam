import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type Message {
  SetIntegrationToken(String)
  SetUser(String)
  SetContext(String)
  CreateTransport(String)
  Get(Subject(Int))
}

pub type State {
  State(
    integration_token: String,
    user: String,
    context: Option(String),
    transport: Transport,
  )
}

pub fn main() {
  // Start an actor
  let assert Ok(actor) =
    actor.new(0)
    |> actor.on_message(handle_message)
    |> actor.start



  // Send a message and get a reply
  assert actor.call(actor.data, waiting: 10, sending: Get) == 8
}

pub fn handle_message() {

}
