import typeid

pub type InitialState {
  InitialState(
    integration_token: String,
    user: String,
  )
}

pub fn init(integration_token: String, user: String) -> Result(Nil, String) {
  case integration_token {
    "" -> Error("Integration token is required")
    _ -> {
      // создать state
      // запустить actor
      // вернуть итоговый Result
    }
  }
  Ok(Nil)
}

fn generate_user() -> String {
  let assert Ok(id) = typeid.new("user")
  typeid.to_string(id)
}

fn create_initial_state(integration_token: String, user: String) -> InitialState {
  case user {
    "" -> InitialState(integration_token, generate_user())
    _ -> InitialState(integration_token, user)
  }
}