import event
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleam/string
import hawk_gleam as hawk

const default_count = 10_000

const progress_every = 1000

@external(erlang, "generator_ffi", "now_ms")
fn now_ms() -> Int

@external(erlang, "generator_ffi", "args")
fn args() -> List(String)

type Counts {
  Counts(enqueued: Int, errors: Int)
}

pub fn main() -> Nil {
  let count = event_count()
  let drain_ms = drain_sleep_ms(count)

  io.println(string.concat(["sending ", int.to_string(count), " events"]))

  let assert Ok(_) =
    hawk.init("load-test-token", option.Some("http://127.0.0.1:8787/"))

  let started = now_ms()
  let counts = send_loop(0, count, Counts(0, 0))
  let elapsed = now_ms() - started

  print_report(counts, elapsed, drain_ms)
  io.println(
    string.concat([
      "waiting ",
      int.to_string(drain_ms),
      "ms for HTTP workers to drain — then compare enqueued with collector received=",
    ]),
  )
  process.sleep(drain_ms)
  io.println("generator done")
}

fn event_count() -> Int {
  case args() {
    [raw] ->
      case int.parse(raw) {
        Ok(n) if n > 0 -> n
        _ -> default_count
      }
    _ -> default_count
  }
}

fn drain_sleep_ms(count: Int) -> Int {
  count * 2
  |> int.max(5000)
  |> int.min(60_000)
}

fn send_loop(i: Int, total: Int, counts: Counts) -> Counts {
  case i >= total {
    True -> counts
    False -> {
      let result =
        hawk.send(event.EventPayload(
          title: "load test event",
          event_type: option.Some("error"),
          context: option.Some([#("seq", json.int(i))]),
          user: option.None,
        ))

      let counts = case result {
        Ok(_) -> Counts(..counts, enqueued: counts.enqueued + 1)
        Error(_) -> Counts(..counts, errors: counts.errors + 1)
      }

      let next = i + 1
      case next % progress_every == 0 {
        True ->
          io.println(
            string.concat([
              "enqueued ",
              int.to_string(counts.enqueued),
              "/",
              int.to_string(total),
              " errors=",
              int.to_string(counts.errors),
            ]),
          )
        False -> Nil
      }

      send_loop(next, total, counts)
    }
  }
}

fn print_report(counts: Counts, elapsed_ms: Int, drain_ms: Int) -> Nil {
  let seconds = int.to_float(elapsed_ms) /. 1000.0
  let offered_rps = case seconds >. 0.0 {
    True -> int.to_float(counts.enqueued) /. seconds
    False -> 0.0
  }

  io.println("--- generator (enqueue, not HTTP) ---")
  io.println(
    string.concat(["enqueued:       ", int.to_string(counts.enqueued)]),
  )
  io.println(string.concat(["enqueue_errors: ", int.to_string(counts.errors)]))
  io.println(string.concat(["elapsed_ms:     ", int.to_string(elapsed_ms)]))
  io.println(string.concat(["offered_rps:    ", float.to_string(offered_rps)]))
  io.println(string.concat(["drain_ms:       ", int.to_string(drain_ms)]))
  io.println("after drain, collector `received` should ≈ enqueued")
}
