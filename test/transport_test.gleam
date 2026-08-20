import transport

pub fn empty_url_test() {
  let result = transport.new("", "token")

  assert result == Error("Invalid URL")
}

pub fn empty_token_test() {
  let result = transport.new("url", "")

  assert result == Error("Invalid Token")
}

pub fn valid_transport_test() {
  let result = transport.new("url", "token")

  assert result == Ok(transport.Transport("url", "token"))
}