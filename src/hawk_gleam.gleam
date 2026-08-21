import catcher
import event
import utils/validation

pub fn init(integration_token: String) -> Result(Nil, String) {
  case validation.validate_integration_token(integration_token) {
    Error(error) -> Error(error)
    Ok(_) -> catcher.start_catcher_actor(integration_token)
  }
}

pub fn send(payload: event.EventPayload) -> Result(Nil, String) {
  
}
