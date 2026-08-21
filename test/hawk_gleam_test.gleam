import event
import gleam/option
import gleeunit
import hawk_gleam as hawk

pub fn main() {
  gleeunit.main()
}

pub fn init_starts_hawk_test() {
  assert hawk.init("test_integration_token") == Ok(Nil)
}

pub fn init_is_idempotent_test() {
  let assert Ok(_) = hawk.init("test_integration_token")
  assert hawk.init("another_token") == Ok(Nil)
}

pub fn init_rejects_empty_token_test() {
  assert hawk.init("")
    == Error("Integration token length must be at least 1 characters")
}

pub fn send_after_init_enqueues_test() {
  let assert Ok(_) = hawk.init("test_integration_token")

  assert hawk.send(event.EventPayload("title", option.None)) == Ok(Nil)
}
