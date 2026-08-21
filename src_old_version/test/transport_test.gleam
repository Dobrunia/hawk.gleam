import gleam/list
import transport

const default_url = "http://127.0.0.1:8787/"

pub fn configures_dedicated_http_profile_test() {
  assert transport.configure(8) == Ok(Nil)
  assert transport.configure(8) == Ok(Nil)
}

pub fn new_empty_url_test() {
  let result = transport.new("")

  assert result.url == default_url
}

pub fn new_valid_url_test() {
  let result = transport.new("url")

  assert result.url == "url"
}

pub fn is_success_status_test() {
  let cases = [
    #(199, False),
    #(200, True),
    #(201, True),
    #(204, True),
    #(299, True),
    #(300, False),
    #(400, False),
    #(404, False),
    #(500, False),
  ]

  list.each(cases, fn(test_case) {
    let #(status, expected) = test_case
    assert transport.is_success_status(status) == expected
  })
}
