import event.{type Event}
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/string

pub type Transport {
  Transport(url: String)
}

const default_url = "https://k1.hawk.so/"

@internal
pub fn is_success_status(status: Int) -> Bool {
  status >= 200 && status < 300
}

@internal
pub fn new(url: String) -> Transport {
  case url {
    "" -> Transport(default_url)
    _ -> Transport(url)
  }
}

@internal
pub fn send(transport: Transport, event: Event) -> Result(Nil, String) {
  let event_json = event.to_json(event)

  case request.to(transport.url) {
    Error(_) -> Error("Invalid transport URL")

    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Post)
        |> request.set_header("content-type", "application/json")
        |> request.set_body(event_json)

      case httpc.send(req) {
        Error(_) -> Error("HTTP request failed")

        Ok(response) -> {
          case is_success_status(response.status) {
            True -> Ok(Nil)
            False ->
              Error(
                string.concat([
                  "HTTP status code ",
                  int.to_string(response.status),
                ]),
              )
          }
        }
      }
    }
  }
}
