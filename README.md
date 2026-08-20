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
