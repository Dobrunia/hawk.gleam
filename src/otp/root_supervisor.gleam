import gleam/erlang/process
import gleam/otp/static_supervisor
import otp/dispatcher
import otp/worker_supervisor

@internal
pub fn start(integration_token: String) -> Result(Nil, String) {
  let worker_factory_name = process.new_name("hawk_http_worker_factory")

  let supervisor =
    static_supervisor.new(static_supervisor.OneForAll)
    |> static_supervisor.add(worker_supervisor.supervised(worker_factory_name))
    |> static_supervisor.add(dispatcher.supervised(
      integration_token,
      worker_factory_name,
    ))

  case static_supervisor.start(supervisor) {
    Ok(_) -> Ok(Nil)

    Error(_) -> Error("Failed to start Hawk root supervisor")
  }
}
