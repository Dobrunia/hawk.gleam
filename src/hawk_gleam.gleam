pub fn init(integration_token: String, user: String) -> Result(Nil, String) {
  case integration_token {
    "" -> Error("Integration token is required")
    _ -> {
      let initial_state = create_initial_state(integration_token, user)
      // создать InitialState
      // запустить actor
      // вернуть итоговый Result
      Ok(Nil)
    }
  }
}
