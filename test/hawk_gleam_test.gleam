import event
import gleam/option
import gleeunit
import hawk_gleam as hawk

pub fn main() {
  gleeunit.main()
}

pub fn init_test() {
  let result = hawk.init("test_integration_token")

  assert result == Ok(Nil)
}

pub fn init_twice_test() {
  assert hawk.init("test_integration_token") == Ok(Nil)
  assert hawk.init("another_token") == Ok(Nil)
}

pub fn init_invalid_integration_token_test() {
  let result = hawk.init("")

  assert result
    == Error("Integration token length must be greater than 1 characters")
}

pub fn send_after_init_test() {
  let assert Ok(_) = hawk.init("test_integration_token")

  let result =
    hawk.send(event.EventPayload("title", option.None, option.None, option.None))

  assert result == Ok(Nil)
}
