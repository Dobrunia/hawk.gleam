import event
import gleam/json
import gleam/option
import gleeunit
import hawk_gleam as hawk

pub fn main() {
  gleeunit.main()
}

pub fn init_test() {
  let result = hawk.init("test_integration_token", option.None)

  assert result == Ok(Nil)
}

pub fn init_twice_test() {
  assert hawk.init("test_integration_token", option.None) == Ok(Nil)
  assert hawk.init("another_token", option.None) == Ok(Nil)
}

pub fn init_invalid_integration_token_test() {
  let result = hawk.init("", option.None)

  assert result
    == Error("Integration token length must be greater than 1 characters")
}

pub fn send_after_init_test() {
  let assert Ok(_) = hawk.init("test_integration_token", option.None)

  let result =
    hawk.send(event.EventPayload("title", option.None, option.None, option.None))

  assert result == Ok(Nil)
}

pub fn send_full_payload_test() {
  let assert Ok(_) = hawk.init("test_integration_token", option.None)

  let result =
    hawk.send(event.EventPayload(
      title: "title",
      event_type: option.Some("error"),
      context: option.Some([#("from", json.string("tests"))]),
      user: option.Some(event.User(
        id: "test-user",
        name: option.Some("Test User"),
        url: option.None,
        photo: option.None,
      )),
    ))

  assert result == Ok(Nil)
}

pub fn send_invalid_payload_still_ok_test() {
  let assert Ok(_) = hawk.init("test_integration_token", option.None)

  let result =
    hawk.send(event.EventPayload("", option.None, option.None, option.None))

  assert result == Ok(Nil)
}
