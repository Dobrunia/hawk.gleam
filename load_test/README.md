# Load test

Fake collector + two generators against local catcher. Measures catcher throughput, not Go.

- `src_old_version/generator` → old catcher (`hawk_gleam_old`)
- `load_test/generator_new` → current `src`

## Terminal 1 — collector

```sh
cd load_test/collector
go run .
```

Stdout every second: `received`, `rps`, `bytes`. `POST /` emulates [hawk.collector](https://github.com/codex-team/hawk.collector) error intake (`token`/`catcherType`/`payload`, JSON `{code,error,message}`). JWT, Redis, Mongo, RabbitMQ skipped. `/stats` and `/reset` are load-test only.

Each intake response is held with a lognormal fake RTT (default p50=60ms, p99=200ms) so one blocking HTTP worker behaves like k1, not localhost. Disable with `FAKE_RTT=0`. Override: `FAKE_RTT_P50_MS`, `FAKE_RTT_P99_MS`.

- Snapshot: `GET http://127.0.0.1:8787/stats`
- Reset counters and latency samples: `POST http://127.0.0.1:8787/reset`

## Terminal 2 — old catcher

```powershell
cd src_old_version/generator
gleam run -- 1000
```

Calls `hawk.init(token, option.Some("http://127.0.0.1:8787/"))`.

## Terminal 2 — current catcher

Hardcode the collector URL in `src/transport.gleam` before this run.

```powershell
cd load_test/generator_new
gleam run -- 10000
```

Calls `hawk.init(token)`. Sends batches of 50 while keeping in-flight under 80 so the pending cap of 100 does not drop events. Then polls `/stats` until drain or 15min timeout.

`hawk.send` is enqueue into the dispatcher, not HTTP. Each generator resets the collector, records the initial `received`, and polls `/stats` until `received_delta == enqueued` or the 120s timeout expires.

Default N is 10000.

