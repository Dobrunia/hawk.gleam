# Load test

Fake collector + generator against local `hawk_gleam` (path dep). Measures catcher throughput, not Go.

## Terminal 1 — collector

```sh
cd load_test/collector
go run .
```

Stdout every second: `received`, `rps`, `bytes`.

- Snapshot: `GET http://127.0.0.1:8787/stats`
- Reset counters and latency samples: `POST http://127.0.0.1:8787/reset`

## Terminal 2 — generator

PowerShell:

```powershell
cd load_test/generator
gleam run -- 10000
```

Generator calls `hawk.init(token, option.Some("http://127.0.0.1:8787/"))`. Production apps pass `option.None`.

`hawk.send` is enqueue into the dispatcher, not HTTP. The generator resets the collector, records the initial `received`, and polls `/stats` until `received_delta == enqueued` or the 120s timeout expires.

The final report includes:

- enqueue and accepted RPS;
- end-to-end enqueue → collector p50/p95/p99 latency;
- peak dispatcher mailbox and pending queue depth;
- peak dispatcher and total BEAM memory;
- dispatcher reductions, BEAM runtime and approximate CPU utilization;
- final delivery gap and worker utilization.

Default N is 10000. Catcher has 8 blocking HTTP workers and a dedicated `hawk_gleam` `httpc` profile capped at 8 sessions/connections. A worker has at most one in-flight request; connections are pooled and reused, not permanently pinned to worker IDs.

Dispatcher pending is an in-memory FIFO capped at 10000 events. Overflow is dropped with `Pending queue capacity exceeded`; the Erlang dispatcher mailbox remains unbounded.
