import transport

pub fn new_uses_default_hawk_url_test() {
  assert transport.new().url == "https://k1.hawk.so/"
}
