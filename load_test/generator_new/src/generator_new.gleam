import event
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import hawk_gleam as hawk

const default_count = 10_000

const progress_every = 1000

const poll_interval_ms = 100

const drain_timeout_ms = 120_000

@external(erlang, "generator_ffi", "now_ms")
fn now_ms() -> Int

@external(erlang, "generator_ffi", "runtime_ms")
fn runtime_ms() -> Int

@external(erlang, "generator_ffi", "wall_clock_ms")
fn wall_clock_ms() -> Int

@external(erlang, "generator_ffi", "memory_bytes")
fn memory_bytes() -> Int

@external(erlang, "generator_ffi", "collector_reset")
fn collector_reset() -> Result(Nil, Nil)

@external(erlang, "generator_ffi", "collector_stats")
fn collector_stats() -> Result(String, Nil)

@external(erlang, "generator_ffi", "args")
fn args() -> List(String)

type Counts {
  Counts(enqueued: Int, errors: Int)
}

type CollectorStats {
  CollectorStats(
    received: Int,
    bytes: Int,
    latency_p50_us: Int,
    latency_p95_us: Int,
    latency_p99_us: Int,
  )
}

pub fn main() -> Nil {
  let count = event_count()

  io.println(string.concat(["sending ", int.to_string(count), " events"]))

  let assert Ok(_) = collector_reset()
  let assert Ok(collector_before) = read_collector_stats()
  let assert Ok(_) = hawk.init("load-test-token")

  let runtime_started = runtime_ms()
  let wall_started = wall_clock_ms()
  let started = now_ms()
  let counts = send_loop(0, count, Counts(0, 0))
  let enqueue_elapsed = now_ms() - started
  print_enqueue_report(counts, enqueue_elapsed)

  let target = collector_before.received + counts.enqueued

  io.println(
    string.concat([
      "polling collector until received reaches ",
      int.to_string(target),
      " (timeout ",
      int.to_string(drain_timeout_ms),
      "ms)",
    ]),
  )

  case wait_for_drain(target, started, memory_bytes()) {
    Error(error) -> io.println(string.concat(["benchmark failed: ", error]))

    Ok(#(collector_after, peak_beam_memory_bytes, delivery_elapsed)) ->
      print_delivery_report(
        collector_before,
        collector_after,
        counts,
        delivery_elapsed,
        peak_beam_memory_bytes,
        runtime_ms() - runtime_started,
        wall_clock_ms() - wall_started,
      )
  }
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

fn send_loop(i: Int, total: Int, counts: Counts) -> Counts {
  case i >= total {
    True -> counts
    False -> {
      let result =
        hawk.send(event.EventPayload(
          title: "load test event",
          event_type: option.Some("error"),
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

fn collector_stats_decoder() -> decode.Decoder(CollectorStats) {
  use received <- decode.field("received", decode.int)
  use bytes <- decode.field("bytes", decode.int)
  use latency_p50_us <- decode.field("latency_p50_us", decode.int)
  use latency_p95_us <- decode.field("latency_p95_us", decode.int)
  use latency_p99_us <- decode.field("latency_p99_us", decode.int)
  decode.success(CollectorStats(
    received,
    bytes,
    latency_p50_us,
    latency_p95_us,
    latency_p99_us,
  ))
}

fn read_collector_stats() -> Result(CollectorStats, String) {
  use body <- result.try(
    collector_stats()
    |> result.map_error(fn(_) { "Collector /stats request failed" }),
  )

  json.parse(body, collector_stats_decoder())
  |> result.map_error(fn(_) { "Collector /stats returned invalid JSON" })
}

fn wait_for_drain(
  target: Int,
  started: Int,
  peak_beam_memory_bytes: Int,
) -> Result(#(CollectorStats, Int, Int), String) {
  let elapsed = now_ms() - started

  case elapsed >= drain_timeout_ms {
    True -> Error("Timed out waiting for collector drain")

    False -> {
      use collector <- result.try(read_collector_stats())
      let peak_beam_memory_bytes =
        int.max(peak_beam_memory_bytes, memory_bytes())

      case collector.received >= target {
        True -> Ok(#(collector, peak_beam_memory_bytes, elapsed))
        False -> {
          process.sleep(poll_interval_ms)
          wait_for_drain(target, started, peak_beam_memory_bytes)
        }
      }
    }
  }
}

fn print_enqueue_report(counts: Counts, elapsed_ms: Int) -> Nil {
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
}

fn print_delivery_report(
  before: CollectorStats,
  after: CollectorStats,
  counts: Counts,
  elapsed_ms: Int,
  peak_beam_memory_bytes: Int,
  runtime_elapsed_ms: Int,
  wall_elapsed_ms: Int,
) -> Nil {
  let delivered = after.received - before.received
  let seconds = int.to_float(elapsed_ms) /. 1000.0
  let accepted_rps = case seconds >. 0.0 {
    True -> int.to_float(delivered) /. seconds
    False -> 0.0
  }
  let cpu_percent = case wall_elapsed_ms > 0 {
    True ->
      int.to_float(runtime_elapsed_ms) /. int.to_float(wall_elapsed_ms) *. 100.0
    False -> 0.0
  }

  io.println("--- delivery (enqueue → collector) ---")
  io.println(
    string.concat(["delivered:                ", int.to_string(delivered)]),
  )
  io.println(
    string.concat(["delivery_elapsed_ms:       ", int.to_string(elapsed_ms)]),
  )
  io.println(
    string.concat(["accepted_rps:              ", float.to_string(accepted_rps)]),
  )
  io.println(
    string.concat([
      "latency_p50_ms:            ",
      float.to_string(int.to_float(after.latency_p50_us) /. 1000.0),
    ]),
  )
  io.println(
    string.concat([
      "latency_p95_ms:            ",
      float.to_string(int.to_float(after.latency_p95_us) /. 1000.0),
    ]),
  )
  io.println(
    string.concat([
      "latency_p99_ms:            ",
      float.to_string(int.to_float(after.latency_p99_us) /. 1000.0),
    ]),
  )
  io.println(
    string.concat([
      "peak_beam_memory_mb:       ",
      float.to_string(int.to_float(peak_beam_memory_bytes) /. 1_048_576.0),
    ]),
  )
  io.println(
    string.concat([
      "beam_runtime_ms:           ",
      int.to_string(runtime_elapsed_ms),
    ]),
  )
  io.println(
    string.concat(["beam_cpu_percent:         ", float.to_string(cpu_percent)]),
  )
  io.println(
    string.concat([
      "delivery_gap:              ",
      int.to_string(counts.enqueued - delivered),
    ]),
  )
}
