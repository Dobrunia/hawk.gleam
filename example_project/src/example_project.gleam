import dot_env
import dot_env/env
import gleam/io
import hawk_gleam

pub fn main() -> Nil {
  dot_env.load_default()

  case env.get_string("HAWK_INTEGRATION_TOKEN") {
    Error(_) | Ok("") ->
      io.println("Copy .env.example to .env and set HAWK_INTEGRATION_TOKEN")

    Ok(token) ->
      case hawk_gleam.init(token) {
        Ok(_) -> io.println("Hawk catcher started")
        Error(reason) -> io.println(reason)
      }
  }
}
