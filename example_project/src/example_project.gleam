import dot_env
import dot_env/env
import example_project/checkout
import example_project/payments
import gleam/erlang/process
import gleam/io
import hawk_gleam as hawk

pub fn main() -> Nil {
  dot_env.load_default()

  case env.get_string("HAWK_INTEGRATION_TOKEN") {
    Error(_) | Ok("") ->
      io.println("Copy .env.example to .env and set HAWK_INTEGRATION_TOKEN")

    Ok(token) -> {
      let assert Ok(_) = hawk.init(token)
      io.println("init done, sending from other modules")

      checkout.place_order("ord-1001")
      payments.charge(1500)
      payments.charge_with_broken_payload()

      io.println("waiting for the HTTP worker before exit")
      process.sleep(3000)
      io.println("exit")
    }
  }
}
