import gleam/int
import gleam/option.{type Option}
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
          " length must be at least ",
          int.to_string(min),
          " characters",
        ]),
      )
    length if length > max ->
      Error(
        string.concat([
          field_name,
          " length must be at most ",
          int.to_string(max),
          " characters",
        ]),
      )
    _ -> Ok(Nil)
  }
}

const min_integration_token_length = 1

const max_integration_token_length = 256

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

pub fn validate_catcher_type(catcher_type: String) -> Result(Nil, String) {
  case catcher_type {
    "errors/default" -> Ok(Nil)
    _ -> Error("Catcher type must be 'errors/default'")
  }
}

const min_title_length = 1

const max_title_length = 128

pub fn validate_title(title: String) -> Result(Nil, String) {
  validate_length(title, min_title_length, max_title_length, "Title")
}

const min_event_type_length = 0

const max_event_type_length = 64

pub fn validate_event_type(event_type: Option(String)) -> Result(Nil, String) {
  case event_type {
    option.None -> Ok(Nil)

    option.Some(value) ->
      validate_length(
        value,
        min_event_type_length,
        max_event_type_length,
        "Event type",
      )
  }
}

const min_user_id_length = 1

const max_user_id_length = 128

pub fn validate_user_id(user_id: String) -> Result(Nil, String) {
  validate_length(user_id, min_user_id_length, max_user_id_length, "User ID")
}
