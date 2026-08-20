import dot_env
import dot_env/env
import gleam/io
import hawk_gleam as hawk

pub fn main() -> Nil {
  dot_env.load_default()

  case env.get_string("HAWK_INTEGRATION_TOKEN") {
    Error(_) | Ok("") ->
      io.println("Copy .env.example to .env and set HAWK_INTEGRATION_TOKEN")

    Ok(token) -> {
      let assert Ok(_) = hawk.init(token)
      let assert Ok(_) = hawk.send("Hawk gleam example")
      Nil
    }
  }
}
