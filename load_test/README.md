# Load test

Fake collector + two generators against local catcher. Measures catcher throughput, not Go.

- `src_old_version/generator` → old catcher (`hawk_gleam_old`)
- `load_test/generator_new` → current `src`

## Terminal 1 — collector

```sh
cd load_test/collector
go run .
```

Stdout every second: `received`, `rps`, `bytes`.

- Snapshot: `GET http://127.0.0.1:8787/stats`
- Reset counters and latency samples: `POST http://127.0.0.1:8787/reset`

## Terminal 2 — old catcher

```powershell
cd src_old_version/generator
gleam run -- 10000
```

Calls `hawk.init(token, option.Some("http://127.0.0.1:8787/"))`.

## Terminal 2 — current catcher

Hardcode the collector URL in `src/transport.gleam` before this run.

```powershell
cd load_test/generator_new
gleam run -- 10000
```

Calls `hawk.init(token)`. Same enqueue + poll loop; current API has no transport arg, context, or `stats()`.

`hawk.send` is enqueue into the dispatcher, not HTTP. Each generator resets the collector, records the initial `received`, and polls `/stats` until `received_delta == enqueued` or the 120s timeout expires.

Default N is 10000.

