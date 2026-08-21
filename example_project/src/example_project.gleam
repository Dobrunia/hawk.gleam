import dot_env
import dot_env/env
import event
import gleam/io
import gleam/option
import hawk_gleam as hawk

pub fn main() -> Nil {
  dot_env.load_default()

  case env.get_string("HAWK_INTEGRATION_TOKEN") {
    Error(_) | Ok("") ->
      io.println("Copy .env.example to .env and set HAWK_INTEGRATION_TOKEN")

    Ok(token) -> {
      let assert Ok(_) = hawk.init(token)
      let assert Ok(_) =
        hawk.send(event.EventPayload(
          title: "Hawk gleam example",
          event_type: option.Some("demo"),
          context: option.Some("example_project after hawk.init"),
          user: option.Some("example-user"),
        ))
      Nil
    }
  }
}
