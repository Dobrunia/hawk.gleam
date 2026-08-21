import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import utils/validation

pub type User {
  User(
    id: String,
    name: Option(String),
    url: Option(String),
    photo: Option(String),
  )
}

pub type EventPayload {
  EventPayload(
    title: String,
    event_type: Option(String),
    context: Option(List(#(String, json.Json))),
    user: Option(User),
  )
}

pub type Event {
  Event(catcher_type: String, integration_token: String, payload: EventPayload)
}

fn validate_payload(payload: EventPayload) -> Result(Nil, String) {
  use _ <- result.try(validation.validate_title(payload.title))
  use _ <- result.try(validation.validate_event_type(payload.event_type))
  use _ <- result.try(validate_context(payload.context))
  use _ <- result.try(validate_user(payload.user))

  Ok(Nil)
}

fn validate_context(
  context: Option(List(#(String, json.Json))),
) -> Result(Nil, String) {
  case context {
    option.None -> Ok(Nil)
    option.Some(fields) ->
      list.try_each(fields, fn(field) {
        let #(key, value) = field
        use _ <- result.try(validation.validate_context_key(key))
        validation.validate_context_value(json.to_string(value))
      })
  }
}

fn validate_user(user: Option(User)) -> Result(Nil, String) {
  case user {
    option.None -> Ok(Nil)

    option.Some(value) -> {
      use _ <- result.try(validation.validate_user_id(value.id))
      use _ <- result.try(validation.validate_user_name(value.name))
      use _ <- result.try(validation.validate_user_url(value.url))
      use _ <- result.try(validation.validate_user_photo(value.photo))
      Ok(Nil)
    }
  }
}

fn optional_json_string(
  fields: List(#(String, json.Json)),
  key: String,
  value: Option(String),
) -> List(#(String, json.Json)) {
  case value {
    option.None -> fields
    option.Some(field) -> list.append(fields, [#(key, json.string(field))])
  }
}

fn user_to_json(user: User) -> json.Json {
  [#("id", json.string(user.id))]
  |> optional_json_string("name", user.name)
  |> optional_json_string("url", user.url)
  |> optional_json_string("photo", user.photo)
  |> json.object
}

fn validate_event(event: Event) -> Result(Nil, String) {
  use _ <- result.try(validation.validate_integration_token(
    event.integration_token,
  ))
  use _ <- result.try(validation.validate_catcher_type(event.catcher_type))
  use _ <- result.try(validate_payload(event.payload))

  Ok(Nil)
}

@internal
pub fn apply_default_user(
  payload: EventPayload,
  default_user: User,
) -> EventPayload {
  case payload.user {
    option.Some(_) -> payload
    option.None -> EventPayload(..payload, user: option.Some(default_user))
  }
}

@internal
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

@internal
pub fn to_json(event: Event) -> String {
  let payload_fields = [
    #("title", json.string(event.payload.title)),
  ]

  let payload_fields = case event.payload.event_type {
    option.Some(value) -> [#("type", json.string(value)), ..payload_fields]

    option.None -> payload_fields
  }

  let payload_fields = case event.payload.context {
    option.Some(fields) -> [#("context", json.object(fields)), ..payload_fields]

    option.None -> payload_fields
  }

  let payload_fields = case event.payload.user {
    option.Some(value) -> [#("user", user_to_json(value)), ..payload_fields]

    option.None -> payload_fields
  }

  json.object([
    #("token", json.string(event.integration_token)),
    #("catcherType", json.string(event.catcher_type)),
    #("payload", json.object(payload_fields)),
  ])
  |> json.to_string
}
