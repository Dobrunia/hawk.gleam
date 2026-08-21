import gleam/erlang/atom
import gleam/erlang/process.{type Name, type Pid}
import gleam/otp/static_supervisor
import otp/dispatcher
import otp/worker_supervisor

@external(erlang, "gleam_erlang_ffi", "identity")
fn atom_to_name(atom: atom.Atom) -> Name(Nil)

fn name() -> Name(Nil) {
  atom.create("hawk_gleam_root_supervisor")
  |> atom_to_name
}

@internal
pub fn pid() -> Result(Pid, Nil) {
  process.named(name())
}

@internal
pub fn start(integration_token: String) -> Result(Nil, String) {
  case pid() {
    Ok(_) -> Ok(Nil)
    Error(_) -> start_new(integration_token)
  }
}

fn start_new(integration_token: String) -> Result(Nil, String) {
  let worker_factory_name = process.new_name("hawk_http_worker_factory")

  let supervisor =
    static_supervisor.new(static_supervisor.OneForAll)
    |> static_supervisor.add(worker_supervisor.supervised(worker_factory_name))
    |> static_supervisor.add(dispatcher.supervised(
      integration_token,
      worker_factory_name,
    ))

  case static_supervisor.start(supervisor) {
    Ok(started) ->
      case process.register(started.pid, name()) {
        Ok(_) -> Ok(Nil)
        Error(_) -> {
          process.unlink(started.pid)
          process.kill(started.pid)

          case pid() {
            Ok(_) -> Ok(Nil)
            Error(_) -> Error("Failed to start Hawk root supervisor")
          }
        }
      }

    Error(_) ->
      case pid(), dispatcher.is_running() {
        Ok(_), _ -> Ok(Nil)
        _, True -> Ok(Nil)
        _, False -> Error("Failed to start Hawk root supervisor")
      }
  }
}
