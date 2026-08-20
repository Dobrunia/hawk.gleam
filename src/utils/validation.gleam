import gleam/int
import gleam/string

fn validate_length(
  value: String,
  min: Int,
  max: Int,
  field_name: String,
) -> Result(Nil, String) {
  case string.length(value) {
    length if length < min ->
      Error(
        string.concat([
          field_name,
          " length must be greater than ",
          int.to_string(min),
          " characters",
        ]),
      )
    length if length > max ->
      Error(
        string.concat([
          field_name,
          " length must be less than ",
          int.to_string(max),
          " characters",
        ]),
      )
    _ -> Ok(Nil)
  }
}

const min_integration_token_length = 1

const max_integration_token_length = 128

pub fn validate_integration_token(
  integration_token: String,
) -> Result(Nil, String) {
  validate_length(
    integration_token,
    min_integration_token_length,
    max_integration_token_length,
    "Integration token",
  )
}

const min_user_length = 0

const max_user_length = 64

pub fn validate_user(user: String) -> Result(Nil, String) {
  validate_length(user, min_user_length, max_user_length, "User")
}
