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

const max_integration_token_length = 256

@internal
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

@internal
pub fn validate_catcher_type(catcher_type: String) -> Result(Nil, String) {
  case catcher_type {
    "errors/default" -> Ok(Nil)
    _ -> Error("Catcher type must be 'errors/default'")
  }
}

const min_title_length = 1

const max_title_length = 128

@internal
pub fn validate_title(title: String) -> Result(Nil, String) {
  validate_length(title, min_title_length, max_title_length, "Title")
}

const min_event_type_length = 0

const max_event_type_length = 64

@internal
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

const min_context_key_length = 1

const max_context_key_length = 64

const min_context_value_length = 0

const max_context_value_length = 128

@internal
pub fn validate_context_key(key: String) -> Result(Nil, String) {
  validate_length(
    key,
    min_context_key_length,
    max_context_key_length,
    "Context key",
  )
}

@internal
pub fn validate_context_value(value: String) -> Result(Nil, String) {
  validate_length(
    value,
    min_context_value_length,
    max_context_value_length,
    "Context value",
  )
}

const min_user_id_length = 1

const max_user_id_length = 64

const min_user_field_length = 0

const max_user_field_length = 64

@internal
pub fn validate_user_id(id: String) -> Result(Nil, String) {
  validate_length(id, min_user_id_length, max_user_id_length, "User id")
}

@internal
pub fn validate_user_name(name: Option(String)) -> Result(Nil, String) {
  validate_optional_user_field(name, "User name")
}

@internal
pub fn validate_user_url(url: Option(String)) -> Result(Nil, String) {
  validate_optional_user_field(url, "User url")
}

@internal
pub fn validate_user_photo(photo: Option(String)) -> Result(Nil, String) {
  validate_optional_user_field(photo, "User photo")
}

fn validate_optional_user_field(
  value: Option(String),
  field_name: String,
) -> Result(Nil, String) {
  case value {
    option.None -> Ok(Nil)
    option.Some(field) ->
      validate_length(
        field,
        min_user_field_length,
        max_user_field_length,
        field_name,
      )
  }
}
