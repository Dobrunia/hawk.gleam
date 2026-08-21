import event
import gleam/json
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

pub fn create_new_and_valid_event_invalid_payload_long_context_key_test() {
  let result =
    event.create_new_and_valid_event(
      "errors/default",
      "test_integration_token",
      event.EventPayload(
        "test_title",
        option.None,
        option.Some([#("a" |> string.repeat(65), json.string("x"))]),
        option.None,
      ),
    )
  assert result == Error("Context key length must be less than 64 characters")
}

pub fn create_new_and_valid_event_invalid_payload_long_context_value_test() {
  let result =
    event.create_new_and_valid_event(
      "errors/default",
      "test_integration_token",
      event.EventPayload(
        "test_title",
        option.None,
        option.Some([#("x", json.string("a" |> string.repeat(129)))]),
        option.None,
      ),
    )
  assert result
    == Error("Context value length must be less than 128 characters")
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
        option.Some([#("msg", json.string("context"))]),
        option.None,
      ),
      "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"context\":{\"msg\":\"context\"},\"title\":\"title\"}}",
    ),
    #(
      event.EventPayload(
        "title",
        option.None,
        option.None,
        option.Some(event.User(
          id: "user-1",
          name: option.Some("Ada"),
          url: option.None,
          photo: option.None,
        )),
      ),
      "{\"token\":\"token\",\"catcherType\":\"errors/default\",\"payload\":{\"user\":{\"id\":\"user-1\",\"name\":\"Ada\"},\"title\":\"title\"}}",
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(payload, expected) = test_case

    let event = event.Event("errors/default", "token", payload)

    assert event.to_json(event) == expected
  })
}

pub fn apply_default_user_fills_none_test() {
  let default =
    event.User(
      id: "user-generated",
      name: option.None,
      url: option.None,
      photo: option.None,
    )

  let payload =
    event.EventPayload("title", option.None, option.None, option.None)

  assert event.apply_default_user(payload, default)
    == event.EventPayload(
      "title",
      option.None,
      option.None,
      option.Some(default),
    )
}

pub fn apply_default_user_keeps_explicit_test() {
  let default =
    event.User(
      id: "user-generated",
      name: option.None,
      url: option.None,
      photo: option.None,
    )

  let explicit =
    event.User(
      id: "buyer-42",
      name: option.Some("Ada"),
      url: option.None,
      photo: option.None,
    )

  let payload =
    event.EventPayload("title", option.None, option.None, option.Some(explicit))

  assert event.apply_default_user(payload, default) == payload
}
