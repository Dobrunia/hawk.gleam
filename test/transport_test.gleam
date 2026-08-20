import transport

pub fn empty_url_test() {
  let result = transport.new("")

  assert result.url == "https://k1.hawk.so/"
}

pub fn valid_transport_test() {
  let result = transport.new("url")

  assert result.url == "url"
}