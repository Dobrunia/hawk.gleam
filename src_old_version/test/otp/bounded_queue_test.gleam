import otp/bounded_queue

pub fn preserves_fifo_order_test() {
  let queue = bounded_queue.new(3)
  let assert Ok(queue) = bounded_queue.push(queue, 1)
  let assert Ok(queue) = bounded_queue.push(queue, 2)
  let assert Ok(queue) = bounded_queue.push(queue, 3)

  let assert Ok(#(1, queue)) = bounded_queue.pop(queue)
  let assert Ok(#(2, queue)) = bounded_queue.pop(queue)
  let assert Ok(#(3, queue)) = bounded_queue.pop(queue)
  assert bounded_queue.pop(queue) == Error(Nil)
}

pub fn rejects_items_at_capacity_test() {
  let queue = bounded_queue.new(2)
  let assert Ok(queue) = bounded_queue.push(queue, "first")
  let assert Ok(queue) = bounded_queue.push(queue, "second")

  assert bounded_queue.size(queue) == 2
  assert bounded_queue.push(queue, "third") == Error(Nil)
}

pub fn frees_capacity_after_pop_test() {
  let queue = bounded_queue.new(1)
  let assert Ok(queue) = bounded_queue.push(queue, "first")
  let assert Ok(#("first", queue)) = bounded_queue.pop(queue)
  let assert Ok(queue) = bounded_queue.push(queue, "second")

  assert bounded_queue.size(queue) == 1
}
