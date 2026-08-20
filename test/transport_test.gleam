import transport

const default_url = "https://k1.hawk.so/"

pub fn test_new_empty_url() {
  let result = transport.new("")

  assert result.url == default_url
}

pub fn test_new_valid_url() {
  let result = transport.new("url")

  assert result.url == "url"
}
