import gleam/erlang/process.{type Name, type Subject}
import gleam/otp/factory_supervisor
import otp/http_worker
import otp/protocol

@internal
pub fn supervised(
  name: Name(
    factory_supervisor.Message(
      http_worker.StartArgument,
      Subject(protocol.WorkerMessage),
    ),
  ),
) {
  factory_supervisor.worker_child(http_worker.start)
  |> factory_supervisor.named(name)
  |> factory_supervisor.supervised
}
