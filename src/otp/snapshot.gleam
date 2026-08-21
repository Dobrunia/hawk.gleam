import event
import gleam/option.{type Option}

/// Durable dispatcher state. Survives dispatcher/worker restart in this VM.
/// Worker subjects are not stored — they die with the processes.
pub type Snapshot {
  Snapshot(
    default_user: event.User,
    pending: List(event.Event),
    inflight: List(event.Event),
    transport: Option(String),
  )
}

@external(erlang, "snapshot_ffi", "get_snapshot")
fn get_snapshot() -> Result(Snapshot, Nil)

@external(erlang, "snapshot_ffi", "put_snapshot")
fn put_snapshot(snapshot: Snapshot) -> Nil

@external(erlang, "snapshot_ffi", "new_user_id")
fn new_user_id() -> String

fn new_user() -> event.User {
  event.User(
    id: new_user_id(),
    name: option.None,
    url: option.None,
    photo: option.None,
  )
}

@internal
pub fn load_or_init() -> Snapshot {
  case get_snapshot() {
    Ok(snapshot) -> snapshot
    Error(_) -> {
      let snapshot = Snapshot(new_user(), [], [], option.None)
      put_snapshot(snapshot)
      snapshot
    }
  }
}

@internal
pub fn save(snapshot: Snapshot) -> Nil {
  put_snapshot(snapshot)
}
