import event
import transport

pub type Snapshot {
  Snapshot(
    default_user: event.User,
    pending: List(event.Event),
    inflight: List(event.Event),
    transport: transport.Transport,
  )
}

@external(erlang, "snapshot_ffi", "get_snapshot")
fn get_snapshot() -> Result(Snapshot, Nil)

@external(erlang, "snapshot_ffi", "put_snapshot")
fn put_snapshot(snapshot: Snapshot) -> Nil

@external(erlang, "snapshot_ffi", "new_user_id")
fn new_user_id() -> String

@internal
pub fn load_or_init() -> Snapshot {
  case get_snapshot() {
    Ok(snapshot) -> snapshot
    Error(_) -> {
      let snapshot =
        Snapshot(
          default_user: event.User(new_user_id()),
          pending: [],
          inflight: [],
          transport: transport.new(),
        )
      put_snapshot(snapshot)
      snapshot
    }
  }
}

@internal
pub fn save(snapshot: Snapshot) -> Nil {
  put_snapshot(snapshot)
}
