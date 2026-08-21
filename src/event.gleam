import gleam/json
import gleam/option.{type Option}
import gleam/result
import utils/validation

pub type User {
  User(id: String)
}

pub type EventPayload {
  EventPayload(title: String, event_type: Option(String))
}

pub type Event {
  Event(
    catcher_type: String,
    integration_token: String,
    user: User,
    payload: EventPayload,
  )
}

fn validate_payload(payload: EventPayload) -> Result(Nil, String) {
  use _ <- result.try(validation.validate_title(payload.title))
  use _ <- result.try(validation.validate_event_type(payload.event_type))

  Ok(Nil)
}

fn validate_event(event: Event) -> Result(Nil, String) {
  use _ <- result.try(validation.validate_integration_token(
    event.integration_token,
  ))
  use _ <- result.try(validation.validate_catcher_type(event.catcher_type))
  use _ <- result.try(validation.validate_user_id(event.user.id))
  use _ <- result.try(validate_payload(event.payload))

  Ok(Nil)
}

@internal
pub fn create_new_and_valid_event(
  catcher_type: String,
  integration_token: String,
  user: User,
  payload: EventPayload,
) -> Result(Event, String) {
  let event = Event(catcher_type, integration_token, user, payload)
  case validate_event(event) {
    Error(error) -> Error(error)
    Ok(_) -> Ok(event)
  }
}

@internal
pub fn to_json(event: Event) -> String {
  let payload_fields = [
    #("title", json.string(event.payload.title)),
    #("user", json.object([#("id", json.string(event.user.id))])),
  ]

  let payload_fields = case event.payload.event_type {
    option.Some(value) -> [#("type", json.string(value)), ..payload_fields]

    option.None -> payload_fields
  }

  json.object([
    #("token", json.string(event.integration_token)),
    #("catcherType", json.string(event.catcher_type)),
    #("payload", json.object(payload_fields)),
  ])
  |> json.to_string
}
