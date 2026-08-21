import transport

pub fn new_uses_default_hawk_url_test() {
  assert transport.new().url == "http://127.0.0.1:8787/"
}
