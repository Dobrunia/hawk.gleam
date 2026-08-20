import gleam/json
import gleam/option.{type Option}
import gleam/result
import utils/validation

pub type EventPayload {
  EventPayload(
    title: String,
    event_type: Option(String),
    context: Option(String),
    user: Option(String),
  )
}

pub type Event {
  Event(catcher_type: String, integration_token: String, payload: EventPayload)
}

fn validate_payload(payload: EventPayload) -> Result(Nil, String) {
  use _ <- result.try(validation.validate_title(payload.title))
  use _ <- result.try(validation.validate_event_type(payload.event_type))
  use _ <- result.try(validation.validate_context(payload.context))
  use _ <- result.try(validation.validate_user(payload.user))

  Ok(Nil)
}

fn validate_event(event: Event) -> Result(Nil, String) {
  use _ <- result.try(validation.validate_integration_token(
    event.integration_token,
  ))
  use _ <- result.try(validation.validate_catcher_type(event.catcher_type))
  use _ <- result.try(validate_payload(event.payload))

  Ok(Nil)
}

pub fn create_new_and_valid_event(
  catcher_type: String,
  integration_token: String,
  payload: EventPayload,
) -> Result(Event, String) {
  let event = Event(catcher_type, integration_token, payload)
  case validate_event(event) {
    Error(error) -> Error(error)
    Ok(_) -> Ok(event)
  }
}

pub fn to_json(event: Event) -> String {
  let payload_fields = [
    #("title", json.string(event.payload.title)),
  ]

  let payload_fields = case event.payload.event_type {
    option.Some(value) -> [#("type", json.string(value)), ..payload_fields]

    option.None -> payload_fields
  }

  let payload_fields = case event.payload.context {
    option.Some(value) -> [#("context", json.string(value)), ..payload_fields]

    option.None -> payload_fields
  }

  let payload_fields = case event.payload.user {
    option.Some(value) -> [#("user", json.string(value)), ..payload_fields]

    option.None -> payload_fields
  }

  json.object([
    #("token", json.string(event.integration_token)),
    #("catcherType", json.string(event.catcher_type)),
    #("payload", json.object(payload_fields)),
  ])
  |> json.to_string
}
