import gleam/io
import gleam/string

pub type Level {
  Log
  Info
  Warning
  Error
}

const prefix = "[Hawk]"

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

@internal
pub fn event_not_sent(reason: String) -> Nil {
  log(string.concat(["Event was not sent: ", reason]), Error)
}
