# Hawk Catcher на Gleam — MVP TODO

## 1. Создать базовую структуру библиотеки

- [x] Создать Gleam-проект.
- [x] Создать модуль `event`.
- [x] Создать модуль `transport`.
- [x] Оставить `hawk_gleam.gleam` как публичную точку входа библиотеки.

---

## 2. Создать `Transport`

- [x] Создать тип `Transport`.
- [x] Добавить `url: String`.
- [x] Добавить `token: String`.
- [x] Создать `new(url, token)`.
- [x] Решить, нужно ли валидировать `url` и `token` при создании транспорта. _(Result, domain validation, make invalid states unrepresentable)_

---

## 3. Создать минимальный `Event`

- [ ] Создать тип `Event`.
- [ ] Определить минимальные поля, которые нужны Hawk для обычного события.
- [ ] Добавить сообщение события.
- [ ] При необходимости добавить простой `context`.
- [ ] Не добавлять поля заранее, если они пока не нужны. _(ADT, Option, моделирование данных)_

---

## 4. Научиться кодировать `Event` в JSON

- [ ] Сделать функцию `Event -> Json`.
- [ ] Проверить, что обязательные поля имеют правильные имена и формат.
- [ ] Научиться кодировать строки.
- [ ] Научиться кодировать optional-поля, если они появятся.
- [ ] Добавить простой тест на ожидаемый JSON. _(pure functions, data transformation, Option)_

---

## 5. Собрать HTTP Request

- [ ] Создать request из `transport.url`.
- [ ] Обработать случай, если URL нельзя превратить в HTTP Request. _(Result, pattern matching)_
- [ ] Установить нужный HTTP method.
- [ ] Добавить integration token.
- [ ] Добавить необходимые headers.
- [ ] Добавить JSON Event в body.
- [ ] Собирать request через последовательные преобразования, а не через mutable state. _(immutability, pipeline, function composition)_

---

## 6. Отправить HTTP Request

- [ ] Выбрать HTTP client для BEAM.
- [ ] Отправить собранный request.
- [ ] Получить `Result(Response, HttpError)`.
- [ ] Отдельно обработать `Ok(response)` и `Error(error)`. _(Result, pattern matching)_
- [ ] Считать успешным только нужный Hawk status code.

---

## 7. Создать свой `SendError`

- [ ] Создать ADT `SendError`.
- [ ] Отделить ошибку сети от HTTP response с плохим status.
- [ ] При необходимости добавить ошибку некорректного response.
- [ ] Преобразовать низкоуровневые ошибки HTTP client в `SendError`. _(ADT, error modelling, domain errors)_

Пример направления:

```text
SendError
├── TransportError(...)
├── BadStatus(Int)
└── InvalidResponse(...)
```

Не обязательно использовать именно такие варианты — определить их по мере реализации.

---

## 8. Закончить `transport.send`

- [ ] Принимать `Transport`.
- [ ] Принимать `Event`.
- [ ] Кодировать `Event` в JSON.
- [ ] Собирать request.
- [ ] Отправлять request.
- [ ] Преобразовывать результат в доменный `Result`.
- [ ] Не делать внутри `send` повторную проверку типов, которые уже гарантирует Gleam. _(type system, referential transparency, separation of concerns)_

Ожидаемая модель:

```text
Transport + Event
       ↓
      JSON
       ↓
HTTP Request
       ↓
HTTP Client
       ↓
Result(Nil, SendError)
```

---

## 9. Сделать первый публичный API catcher

- [ ] Добавить публичную функцию в `hawk_gleam.gleam`.
- [ ] Принимать обычное сообщение.
- [ ] При необходимости принимать context.
- [ ] Создавать из входных данных `Event`.
- [ ] Передавать `Event` в `transport.send`. _(composition, separation between domain and infrastructure)_

Например по смыслу:

```text
capture(...)
   ↓
Event
   ↓
Transport
   ↓
Hawk
```

---

## 10. Добавить Context

- [ ] Определить тип данных для context.
- [ ] Научиться передавать context вместе с событием.
- [ ] Добавить context в JSON Event.
- [ ] Решить, какие значения допустимы внутри context.
- [ ] Если понадобятся произвольные runtime-значения — изучить `Dynamic` и безопасное декодирование. _(Dynamic, Decoder, type boundaries)_

---

## 11. Добавить тесты Event

- [ ] Создание минимального `Event`.
- [ ] Event без context.
- [ ] Event с context.
- [ ] JSON encoding.
- [ ] Проверить, что encoder является обычной pure function. _(pure functions, deterministic testing)_

---

## 12. Добавить тесты Transport

- [ ] Успешный HTTP response.
- [ ] Неуспешный status code.
- [ ] Network error.
- [ ] Некорректный URL.
- [ ] Проверить преобразование HTTP errors в `SendError`. _(Result, exhaustive pattern matching)_

---

## 13. Проверить настоящий запрос в Hawk

- [ ] Создать `Transport` с реальным endpoint и token.
- [ ] Создать простой `Event`.
- [ ] Отправить его через `transport.send`.
- [ ] Проверить, что событие появилось в Hawk.
- [ ] Проверить отправку события с context.

---

## 14. Создать тестовый проект и подготовить релиз

- [ ] Создать рядом с библиотекой отдельный небольшой Gleam-проект, например `example_app` или `test_app`.
- [ ] Подключить `hawk_gleam` как **локальную dependency**, не публикуя пакет. _(package dependencies, локальная разработка библиотеки)_
- [ ] Инициализировать `Transport` с тестовым Hawk endpoint и token.
- [ ] Вызвать публичный API catcher из тестового приложения.
- [ ] Создать контролируемое тестовое событие/ошибку.
- [ ] Проверить, что событие реально появляется в Hawk.
- [ ] Проверить работу context.
- [ ] Использовать этот проект дальше как минимальный integration example для ручного тестирования библиотеки.

Пример структуры репозитория:

```text
hawk-gleam/
├── src/
├── test/
├── gleam.toml
└── example_app/
    ├── src/
    └── gleam.toml
```

Сначала библиотека подключается из локальной директории. Публиковать её для этого не требуется.

Когда MVP стабильно работает:

- [ ] Провести финальное ревью публичного API.
- [ ] Проверить naming типов и функций.
- [ ] Проверить README и минимальный пример подключения.
- [ ] Проверить версию пакета.
- [ ] Опубликовать библиотеку в **Hex** — это основной package registry для Gleam/Erlang ecosystem. _(package publishing, semantic versioning)_
- [ ] После публикации заменить локальную dependency в `example_app` на опубликованную версию из Hex.
- [ ] Ещё раз проверить полный сценарий установки и отправки события как внешний пользователь библиотеки.
