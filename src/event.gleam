import gleam/option.{type Option}

pub type EventPayload {
  EventPayload(
    title: String,
    event_type: Option(String),
    context: Option(String),
    user: Option(String),
  )
}

pub type Event {
  Event(catcher_type: String, integration_token: String, payload: EventPayload)
}

const default_catcher_type = "errors/default"

pub fn create_new_event(
  integration_token: String,
  payload: EventPayload,
) -> Event {
  Event(default_catcher_type, integration_token, payload)
}
