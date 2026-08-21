import gleam/list

pub opaque type Queue(item) {
  Queue(next: List(item), incoming: List(item), size: Int, capacity: Int)
}

@internal
pub fn new(capacity: Int) -> Queue(item) {
  Queue(next: [], incoming: [], size: 0, capacity: capacity)
}

@internal
pub fn size(queue: Queue(item)) -> Int {
  queue.size
}

@internal
pub fn push(queue: Queue(item), item: item) -> Result(Queue(item), Nil) {
  case queue.size >= queue.capacity {
    True -> Error(Nil)
    False ->
      Ok(
        Queue(..queue, incoming: [item, ..queue.incoming], size: queue.size + 1),
      )
  }
}

@internal
pub fn pop(queue: Queue(item)) -> Result(#(item, Queue(item)), Nil) {
  case queue.next {
    [item, ..rest] ->
      Ok(#(item, Queue(..queue, next: rest, size: queue.size - 1)))

    [] ->
      case list.reverse(queue.incoming) {
        [] -> Error(Nil)
        [item, ..rest] ->
          Ok(#(
            item,
            Queue(
              next: rest,
              incoming: [],
              size: queue.size - 1,
              capacity: queue.capacity,
            ),
          ))
      }
  }
}
