# hawk_gleam

Hawk.so error catcher for Gleam (Erlang target).

```sh
gleam add hawk_gleam
```

```gleam
import event
import gleam/option
import hawk_gleam as hawk

pub fn main() -> Nil {
  let assert Ok(_) = hawk.init("YOUR_INTEGRATION_TOKEN", option.None)
  let assert Ok(_) =
    hawk.send(event.EventPayload(
      title: "Hello from Hawk",
      event_type: option.None,
      context: option.None,
      user: option.None,
    ))
  Nil
}
```

`hawk.init` starts 8 HTTP workers by default. Override the pool size without
changing the default API:

```gleam
hawk.init_with_options(
  "YOUR_INTEGRATION_TOKEN",
  option.None,
  hawk.Options(worker_count: 16),
)
```

Each worker has at most one in-flight request. Hawk uses an isolated `httpc`
profile with the same session/connection limit as `worker_count`; connections
are pooled rather than permanently assigned to worker IDs.

## Development

```sh
gleam test
gleam format
gleam check
```

Local usage demo (uses this repo via a path dependency, not Hex). Copy `.env.example` first — `.env` is gitignored:

```sh
cd example_project
cp .env.example .env
```

Put the Hawk integration token into `HAWK_INTEGRATION_TOKEN` in `.env`, then:

```sh
gleam run
```
