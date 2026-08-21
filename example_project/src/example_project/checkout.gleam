import event
import gleam/json
import gleam/option
import hawk_gleam as hawk

/// Pretend checkout service. No init here — uses the singleton from `main`.
pub fn place_order(order_id: String) -> Nil {
  let assert Ok(_) =
    hawk.send(event.EventPayload(
      title: "Order placed",
      event_type: option.Some("info"),
      context: option.Some([
        #("module", json.string("example_project/checkout.place_order")),
        #("order_id", json.string(order_id)),
      ]),
      user: option.Some(event.User(
        id: "buyer-42",
        name: option.Some("buyer-42"),
        url: option.None,
        photo: option.None,
      )),
    ))
  Nil
}
