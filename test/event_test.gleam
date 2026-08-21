import event
import gleam/option
import gleam/string

fn valid_event(payload: event.EventPayload) -> event.Event {
  let assert Ok(event) =
    event.create_new_and_valid_event(
      "errors/default",
      "token",
      event.User("user-1"),
      payload,
    )
  event
}

pub fn create_valid_event_test() {
  let payload = event.EventPayload("title", option.None)

  assert event.create_new_and_valid_event(
      "errors/default",
      "token",
      event.User("user-1"),
      payload,
    )
    == Ok(event.Event("errors/default", "token", event.User("user-1"), payload))
}

pub fn create_rejects_catcher_type_test() {
  assert event.create_new_and_valid_event(
      "errors/custom",
      "token",
      event.User("user-1"),
      event.EventPayload("title", option.None),
    )
    == Error("Catcher type must be 'errors/default'")
}

pub fn create_rejects_empty_title_test() {
  assert event.create_new_and_valid_event(
      "errors/default",
      "token",
      event.User("user-1"),
      event.EventPayload("", option.None),
    )
    == Error("Title length must be at least 1 characters")
}

pub fn create_rejects_empty_user_id_test() {
  assert event.create_new_and_valid_event(
      "errors/default",
      "token",
      event.User(""),
      event.EventPayload("title", option.None),
    )
    == Error("User ID length must be at least 1 characters")
}

pub fn to_json_includes_generated_user_test() {
  assert event.to_json(valid_event(event.EventPayload("title", option.None)))
    == "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"title\":\"title\",\"user\":{\"id\":\"user-1\"}}}"
}

pub fn to_json_includes_optional_type_test() {
  assert event.to_json(
      valid_event(event.EventPayload("title", option.Some("error"))),
    )
    == "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"type\":\"error\",\"title\":\"title\",\"user\":{\"id\":\"user-1\"}}}"
}

pub fn to_json_escapes_payload_strings_test() {
  let json =
    event.to_json(valid_event(event.EventPayload("say \"hi\"", option.None)))

  assert string.contains(json, "say \\\"hi\\\"")
}
