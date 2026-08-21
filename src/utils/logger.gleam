import gleam/io
import gleam/string

pub type Level {
  Log
  Info
  Warning
  Error
}

const prefix = "[Hawk]"

@internal
pub fn log(message: String, level: Level) -> Nil {
  let level = case level {
    Log -> ""
    Info -> "[INFO]"
    Warning -> "[WARN]"
    Error -> "[ERROR]"
  }

  io.println(
    string.concat([
      prefix,
      " ",
      level,
      " ",
      message,
    ]),
  )
}
