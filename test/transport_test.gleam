import transport

const default_url = "https://k1.hawk.so/"

pub fn default_transport_test() {
  let result = transport.new()

  assert result.url == default_url
}

pub fn empty_url_test() {
  let result = transport.new("")

  assert result.url == default_url
}

pub fn valid_transport_test() {
  let result = transport.new("url")

  assert result.url == "url"
}