import event
import gleam/option
import gleam/string
import hawk_gleam as hawk

/// Pretend checkout service. No init here — uses the singleton from `main`.
pub fn place_order(order_id: String) -> Nil {
  let assert Ok(_) =
    hawk.send(event.EventPayload(
      title: string.concat(["Order placed: ", order_id]),
      event_type: option.Some("info"),
    ))
  Nil
}
