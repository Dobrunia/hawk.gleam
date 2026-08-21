import event.{type Event}
import gleam/http/request
import gleam/int
import gleam/string

pub type Transport {
  Transport(url: String)
}

const default_url = "https://k1.hawk.so/"

@external(erlang, "transport_ffi", "configure")
fn configure_ffi(max_connections: Int) -> Result(Nil, Nil)

@external(erlang, "transport_ffi", "send")
fn send_ffi(url: String, body: String) -> Result(Int, Nil)

@internal
pub fn configure(max_connections: Int) -> Result(Nil, String) {
  case configure_ffi(max_connections) {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error("Failed to configure Hawk HTTP client")
  }
}

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

    Ok(_) ->
      case send_ffi(transport.url, event_json) {
        Error(_) -> Error("HTTP request failed")

        Ok(status) -> {
          case is_success_status(status) {
            True -> Ok(Nil)
            False ->
              Error(string.concat(["HTTP status code ", int.to_string(status)]))
          }
        }
      }
  }
}
