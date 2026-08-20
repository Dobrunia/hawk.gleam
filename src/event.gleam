pub type EventPayload {
    EventPayload(
        data: String,
    )
}

pub type Event {
    Event(
        catcher_type: String,
        integration_token: String,
        payload: EventPayload,
    )
}

const default_catcher_type = "error/gleam"

pub fn new_event(integration_token: String, payload: EventPayload) -> Event {
    case integration_token {
        "" -> //как тут выдать ошибку?
    }
    Event(default_catcher_type, integration_token, payload)
}

