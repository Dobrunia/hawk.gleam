import gleam/string
import otp/snapshot
import transport

pub fn load_or_init_keeps_the_same_user_test() {
  let first = snapshot.load_or_init()
  let second = snapshot.load_or_init()

  assert first.default_user.id == second.default_user.id
  assert string.starts_with(first.default_user.id, "user-")
  assert first.transport.url == transport.new().url
}
