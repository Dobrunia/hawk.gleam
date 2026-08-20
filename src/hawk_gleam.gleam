import gleam/io

type Catcher {
  Catcher(
    integration_token: String,
    user: String,
    context: String,
  )
}

pub fn init(integration_token: String, user: String, context: String) -> Result(Catcher, String) {
  case integration_token, user {
    "", _ -> Result.Error("Integration token is required")
    _, "" -> generate_user()
  }
  set_context(context)

  
  // валидация -> сет токена
  // валидация -> сет пользователя
  // сет контекста
  // создание транспорта
  // создание лушателя на ошибки, лучше чтобы запускался отправлял событие и выключался.
}

pub fn init(integration_token: String, user: String) -> Nil {
  init(integration_token, user, "")
}

pub fn init(integration_token: String) -> Nil {
  init(integration_token, "", "")
}