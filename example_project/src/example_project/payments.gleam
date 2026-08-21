import event
import gleam/int
import gleam/option
import gleam/string
import hawk_gleam as hawk

pub fn charge(amount: Int) -> Nil {
  let assert Ok(_) =
    hawk.send(event.EventPayload(
      title: string.concat(["Payment charged: ", int.to_string(amount)]),
      event_type: option.Some("info"),
    ))
  Nil
}

/// Empty title → dispatcher logs, send still returns Ok.
pub fn charge_with_broken_payload() -> Nil {
  let assert Ok(_) =
    hawk.send(event.EventPayload(title: "", event_type: option.Some("error")))
  Nil
}
