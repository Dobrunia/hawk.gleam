import event.{type Event}
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/option.{type Option}
import utils/logger

pub type Transport {
  Transport(url: String)
}

const default_url = "https://k1.hawk.so/"

pub fn new(url: String) -> Transport {
  case url {
    "" -> Transport(default_url)
    _ -> Transport(url)
  }
}

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
          case response.status {
            200 -> Ok(Nil)

            _ -> {
              logger.log("Hawk returned unsuccessful HTTP status", logger.Error)
              Error("Hawk returned unsuccessful HTTP status")
            }
          }
        }
      }
    }
  }
}
