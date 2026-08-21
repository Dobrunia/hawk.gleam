import otp/snapshot

pub fn load_or_init_is_stable_test() {
  let first = snapshot.load_or_init()
  let second = snapshot.load_or_init()

  assert first.default_user.id == second.default_user.id
  assert first.default_user.id != ""
}
