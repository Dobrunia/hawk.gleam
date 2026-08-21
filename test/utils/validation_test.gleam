import gleam/list
import gleam/option
import gleam/string
import utils/validation

pub fn validate_integration_token_test() {
  [
    #("", Error("Integration token length must be at least 1 characters")),
    #("a", Ok(Nil)),
    #("a" |> string.repeat(256), Ok(Nil)),
    #(
      "a" |> string.repeat(257),
      Error("Integration token length must be at most 256 characters"),
    ),
  ]
  |> list.each(fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_integration_token(value) == expected
  })
}

pub fn validate_catcher_type_test() {
  [
    #("errors/default", Ok(Nil)),
    #("", Error("Catcher type must be 'errors/default'")),
    #("errors/custom", Error("Catcher type must be 'errors/default'")),
  ]
  |> list.each(fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_catcher_type(value) == expected
  })
}

pub fn validate_title_test() {
  [
    #("", Error("Title length must be at least 1 characters")),
    #("a", Ok(Nil)),
    #("a" |> string.repeat(128), Ok(Nil)),
    #(
      "a" |> string.repeat(129),
      Error("Title length must be at most 128 characters"),
    ),
  ]
  |> list.each(fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_title(value) == expected
  })
}

pub fn validate_event_type_test() {
  [
    #(option.None, Ok(Nil)),
    #(option.Some(""), Ok(Nil)),
    #(option.Some("error"), Ok(Nil)),
    #(option.Some("a" |> string.repeat(64)), Ok(Nil)),
    #(
      option.Some("a" |> string.repeat(65)),
      Error("Event type length must be at most 64 characters"),
    ),
  ]
  |> list.each(fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_event_type(value) == expected
  })
}

pub fn validate_user_id_test() {
  [
    #("", Error("User ID length must be at least 1 characters")),
    #("user-1", Ok(Nil)),
    #("a" |> string.repeat(128), Ok(Nil)),
    #(
      "a" |> string.repeat(129),
      Error("User ID length must be at most 128 characters"),
    ),
  ]
  |> list.each(fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_user_id(value) == expected
  })
}
