import event
import gleam/option.{type Option}
import otp/dispatcher
import otp/root_supervisor
import utils/validation

pub fn init(
  integration_token: String,
  transport: Option(String),
) -> Result(Nil, String) {
  case validation.validate_integration_token(integration_token) {
    Error(error) -> Error(error)

    Ok(_) ->
      case dispatcher.is_running() {
        True -> Ok(Nil)
        False -> root_supervisor.start(integration_token, transport)
      }
  }
}

pub fn send(payload: event.EventPayload) -> Result(Nil, String) {
  dispatcher.enqueue(payload)
}
