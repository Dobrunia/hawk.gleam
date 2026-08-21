# Load test

Fake collector + generator against local `hawk_gleam` (path dep). Measures catcher throughput, not Go.

## Terminal 1 — collector

```sh
cd load_test/collector
go run .
```

Stdout every second: `received`, `rps`, `bytes`. Snapshot: `GET http://127.0.0.1:8787/stats`

## Terminal 2 — generator

PowerShell:

```powershell
cd load_test/generator
gleam run -- 10000
```

Generator calls `hawk.init(token, option.Some("http://127.0.0.1:8787/"))`. Production apps pass `option.None`.

Prints `enqueued` / `enqueue_errors` / `offered_rps`. `hawk.send` is enqueue into the dispatcher, not HTTP. After drain sleep, collector `received` should be ≈ `enqueued`. Gap = pending, in-flight, or `Event was not sent` on the generator console.

Default N is 10000. Catcher has 2 blocking HTTP workers — accepted RPS is that pool, not offered RPS.
