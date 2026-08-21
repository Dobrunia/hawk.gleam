import gleam/string

pub type Level {
  Log
  Info
  Warning
  Error
}

const prefix = "[Hawk]"

@external(erlang, "hawk_gleam_ffi", "println")
fn println(text: String) -> Nil

@internal
pub fn log(message: String, level: Level) -> Nil {
  let level = case level {
    Log -> ""
    Info -> "[INFO]"
    Warning -> "[WARN]"
    Error -> "[ERROR]"
  }

  println(string.concat([prefix, " ", level, " ", message]))
}
