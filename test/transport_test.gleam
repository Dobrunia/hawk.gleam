import transport

const default_url = "https://k1.hawk.so/"

pub fn new_empty_url_test() {
  let result = transport.new("")

  assert result.url == default_url
}

pub fn new_valid_url_test() {
  let result = transport.new("url")

  assert result.url == "url"
}
