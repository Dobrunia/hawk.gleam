import event
import gleam/list
import gleam/option
import gleam/string

pub fn create_new_and_valid_event_test() {
  let result =
    event.create_new_and_valid_event(
      "errors/default",
      "test_integration_token",
      event.EventPayload("test_title", option.None, option.None, option.None),
    )
  assert result
    == Ok(event.Event(
      "errors/default",
      "test_integration_token",
      event.EventPayload("test_title", option.None, option.None, option.None),
    ))
}

pub fn create_new_and_valid_event_invalid_catcher_type_test() {
  let result =
    event.create_new_and_valid_event(
      "",
      "test_integration_token",
      event.EventPayload("test_title", option.None, option.None, option.None),
    )
  assert result == Error("Catcher type must be 'errors/default'")
}

pub fn create_new_and_valid_event_invalid_integration_token_test() {
  let result =
    event.create_new_and_valid_event(
      "errors/default",
      "",
      event.EventPayload("test_title", option.None, option.None, option.None),
    )
  assert result
    == Error("Integration token length must be greater than 1 characters")
}

pub fn create_new_and_valid_event_invalid_payload_test() {
  let result =
    event.create_new_and_valid_event(
      "errors/default",
      "test_integration_token",
      event.EventPayload("", option.None, option.None, option.None),
    )
  assert result == Error("Title length must be greater than 1 characters")
}

pub fn create_new_and_valid_event_invalid_payload_long_title_test() {
  let result =
    event.create_new_and_valid_event(
      "errors/default",
      "test_integration_token",
      event.EventPayload(
        "a" |> string.repeat(129),
        option.None,
        option.None,
        option.None,
      ),
    )
  assert result == Error("Title length must be less than 128 characters")
}

pub fn create_new_and_valid_event_invalid_payload_long_context_test() {
  let result =
    event.create_new_and_valid_event(
      "errors/default",
      "test_integration_token",
      event.EventPayload(
        "test_title",
        option.None,
        option.Some("a" |> string.repeat(129)),
        option.None,
      ),
    )
  assert result == Error("Context length must be less than 128 characters")
}

pub fn to_json_test() {
  let cases = [
    #(
      event.EventPayload("title", option.None, option.None, option.None),
      "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"title\":\"title\"}}",
    ),
    #(
      event.EventPayload("title", option.Some("type"), option.None, option.None),
      "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"type\":\"type\",\"title\":\"title\"}}",
    ),
    #(
      event.EventPayload(
        "title",
        option.None,
        option.Some("context"),
        option.None,
      ),
      "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"context\":\"context\",\"title\":\"title\"}}",
    ),
    #(
      event.EventPayload("title", option.None, option.None, option.Some("user")),
      "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"user\":\"user\",\"title\":\"title\"}}",
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(payload, expected) = test_case

    let event = event.Event("errors/default", "token", payload)

    assert event.to_json(event) == expected
  })
}
