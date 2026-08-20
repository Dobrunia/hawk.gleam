import catcher

pub fn init(integration_token: String, user: String) -> Result(Nil, String) {
  case integration_token {
    "" -> Error("Integration token is required")
    _ -> catcher.start_catcher_actor(integration_token, user)
  }
}
