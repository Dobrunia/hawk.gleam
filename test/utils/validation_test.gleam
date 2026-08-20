import gleam/list
import gleam/option
import gleam/string
import utils/validation

pub fn validate_integration_token_test() {
  let cases = [
    #("", Error("Integration token length must be greater than 1 characters")),
    #("a", Ok(Nil)),
    #("a" |> string.repeat(128), Ok(Nil)),
    #(
      "a" |> string.repeat(129),
      Error("Integration token length must be less than 128 characters"),
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

pub fn validate_context_test() {
  let cases = [
    #(option.None, Ok(Nil)),
    #(option.Some(""), Ok(Nil)),
    #(option.Some("context"), Ok(Nil)),
    #(option.Some("a" |> string.repeat(128)), Ok(Nil)),
    #(
      option.Some("a" |> string.repeat(129)),
      Error("Context length must be less than 128 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_context(value) == expected
  })
}

pub fn validate_user_test() {
  let cases = [
    #(option.None, Ok(Nil)),
    #(option.Some(""), Ok(Nil)),
    #(option.Some("user"), Ok(Nil)),
    #(option.Some("a" |> string.repeat(64)), Ok(Nil)),
    #(
      option.Some("a" |> string.repeat(65)),
      Error("User length must be less than 64 characters"),
    ),
  ]

  list.each(cases, fn(test_case) {
    let #(value, expected) = test_case
    assert validation.validate_user(value) == expected
  })
}
