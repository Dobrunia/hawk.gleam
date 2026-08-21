import event
import gleam/json
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