import event
import otp/dispatcher
import otp/root_supervisor
import utils/validation

pub fn init(integration_token: String) -> Result(Nil, String) {
  case validation.validate_integration_token(integration_token) {
    Error(error) -> Error(error)
    Ok(_) -> root_supervisor.start(integration_token)
  }
}

pub fn send(payload: event.EventPayload) -> Result(Nil, String) {
  dispatcher.enqueue(payload)
}
