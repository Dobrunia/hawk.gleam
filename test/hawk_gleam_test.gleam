import gleeunit
import hawk_gleam as hawk

pub fn main() {
  gleeunit.main()
}

pub fn test_init() {
  let result = hawk.init("test_integration_token")

  assert result == Ok(Nil)
}

pub fn test_init_invalid_integration_token() {
  let result = hawk.init("")

  assert result == Error("Invalid integration token")
}
