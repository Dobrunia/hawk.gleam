import gleam/list
import gleam/option
import gleam/string
import utils/validation

pub fn validate_integration_token_test() {
  let cases = [
    #("", Error("Integration token length must be greater than 1 characters")),
    #("a", Ok(Nil)),
    #("a" |> string.repeat(256), Ok(Nil)),
    #(
      "a" |> string.repeat(257),
      Error("Integration token length must be less than 256 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_integration_token(value) == expected
  })
}

pub fn validate_catcher_type_test() {
  let cases = [
    #("errors/default", Ok(Nil)),
    #("", Error("Catcher type must be 'errors/default'")),
    #("errors/custom", Error("Catcher type must be 'errors/default'")),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_catcher_type(value) == expected
  })
}

pub fn validate_title_test() {
  let cases = [
    #("", Error("Title length must be greater than 1 characters")),
    #("a", Ok(Nil)),
    #("a" |> string.repeat(128), Ok(Nil)),
    #(
      "a" |> string.repeat(129),
      Error("Title length must be less than 128 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_title(value) == expected
  })
}

pub fn validate_event_type_test() {
  let cases = [
    #(option.None, Ok(Nil)),
    #(option.Some(""), Ok(Nil)),
    #(option.Some("error"), Ok(Nil)),
    #(option.Some("a" |> string.repeat(64)), Ok(Nil)),
    #(
      option.Some("a" |> string.repeat(65)),
      Error("Event type length must be less than 64 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_event_type(value) == expected
  })
}

pub fn validate_context_key_test() {
  let cases = [
    #("", Error("Context key length must be greater than 1 characters")),
    #("module", Ok(Nil)),
    #("a" |> string.repeat(64), Ok(Nil)),
    #(
      "a" |> string.repeat(65),
      Error("Context key length must be less than 64 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_context_key(value) == expected
  })
}

pub fn validate_context_value_test() {
  let cases = [
    #("", Ok(Nil)),
    #("\"ok\"", Ok(Nil)),
    #("a" |> string.repeat(128), Ok(Nil)),
    #(
      "a" |> string.repeat(129),
      Error("Context value length must be less than 128 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_context_value(value) == expected
  })
}

pub fn validate_user_id_test() {
  let cases = [
    #("", Error("User id length must be greater than 1 characters")),
    #("a", Ok(Nil)),
    #("a" |> string.repeat(64), Ok(Nil)),
    #(
      "a" |> string.repeat(65),
      Error("User id length must be less than 64 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_user_id(value) == expected
  })
}

pub fn validate_user_name_test() {
  let cases = [
    #(option.None, Ok(Nil)),
    #(option.Some(""), Ok(Nil)),
    #(option.Some("Ada"), Ok(Nil)),
    #(
      option.Some("a" |> string.repeat(65)),
      Error("User name length must be less than 64 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_user_name(value) == expected
  })
}
