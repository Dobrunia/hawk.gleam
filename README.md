# hawk_gleam

Hawk.so error catcher for Gleam (Erlang target).

```sh
gleam add hawk_gleam
```

```gleam
import hawk_gleam

pub fn main() -> Nil {
  let assert Ok(_) = hawk_gleam.init("YOUR_INTEGRATION_TOKEN")
  Nil
}
```

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
