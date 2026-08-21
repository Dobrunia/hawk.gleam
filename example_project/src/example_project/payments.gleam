import event
import gleam/json
import gleam/option
import hawk_gleam as hawk

pub fn charge(amount: Int) -> Nil {
  let assert Ok(_) =
    hawk.send(event.EventPayload(
      title: "Payment charged",
      event_type: option.Some("info"),
      context: option.Some([
        #("module", json.string("example_project/payments.charge")),
        #("amount", json.int(amount)),
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

/// Empty title → dispatcher logs, send still returns Ok.
pub fn charge_with_broken_payload() -> Nil {
  let assert Ok(_) =
    hawk.send(event.EventPayload(
      title: "",
      event_type: option.Some("error"),
      context: option.Some([
        #(
          "module",
          json.string("example_project/payments.charge_with_broken_payload"),
        ),
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
