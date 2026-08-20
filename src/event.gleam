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