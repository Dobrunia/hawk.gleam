import gleeunit
import hawk_gleam as hawk

pub fn main() {
  gleeunit.main()
}

pub fn init_test() {
  let result = hawk.init("test_integration_token")

  assert result == Ok(Nil)
}

pub fn init_invalid_integration_token_test() {
  let result = hawk.init("")

  assert result
    == Error("Integration token length must be greater than 1 characters")
}
