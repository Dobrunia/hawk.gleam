import event
import gleam/option.{type Option}
import otp/dispatcher
import otp/root_supervisor
import utils/validation

pub type Stats {
  Stats(
    pending: Int,
    peak_pending: Int,
    mailbox: Int,
    memory_bytes: Int,
    reductions: Int,
    busy_workers: Int,
    total_workers: Int,
  )
}

pub type Options {
  Options(worker_count: Int)
}

pub fn default_options() -> Options {
  Options(worker_count: 8)
}

pub fn init(
  integration_token: String,
  transport: Option(String),
) -> Result(Nil, String) {
  init_with_options(integration_token, transport, default_options())
}

pub fn init_with_options(
  integration_token: String,
  transport: Option(String),
  options: Options,
) -> Result(Nil, String) {
  case validation.validate_integration_token(integration_token) {
    Error(error) -> Error(error)

    Ok(_) -> {
      case options.worker_count > 0 {
        False -> Error("Worker count must be greater than 0")
        True ->
          case dispatcher.is_running() {
            True -> Ok(Nil)
            False ->
              root_supervisor.start(
                integration_token,
                transport,
                options.worker_count,
              )
          }
      }
    }
  }
}

pub fn send(payload: event.EventPayload) -> Result(Nil, String) {
  dispatcher.enqueue(payload)
}

pub fn stats() -> Result(Stats, String) {
  case dispatcher.stats() {
    Error(error) -> Error(error)
    Ok(stats) ->
      Ok(Stats(
        pending: stats.pending,
        peak_pending: stats.peak_pending,
        mailbox: stats.mailbox,
        memory_bytes: stats.memory_bytes,
        reductions: stats.reductions,
        busy_workers: stats.busy_workers,
        total_workers: stats.total_workers,
      ))
  }
}
