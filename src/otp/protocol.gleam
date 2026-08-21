import event
import gleam/erlang/process.{type Subject}

pub type WorkerMessage {
  ProcessEvent(event.Event)
}

pub type DispatcherStats {
  DispatcherStats(
    pending: Int,
    peak_pending: Int,
    mailbox: Int,
    memory_bytes: Int,
    reductions: Int,
    busy_workers: Int,
    total_workers: Int,
  )
}

pub type DispatcherMessage {
  Enqueue(event.EventPayload)
  WorkerReady(Int)
  WorkerOnline(Int, Subject(WorkerMessage))
  GetStats(Int, Int, Int, Subject(DispatcherStats))
}
