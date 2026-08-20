Итоговый вариант для Hawk

Я бы сделал так:

hawk_gleam
│
├── init(token)
│
│
└── Hawk Supervisor
        |
        |
        +── Dispatcher
        |
        |
        +── Worker Supervisor
                 |
                 +── HTTP Worker
                 +── HTTP Worker
                 +── HTTP Worker
API наружу

Оставить максимально простым:

hawk.init("token")


hawk.send(payload)

Пользователь ничего не знает про actor.

Что поменять у тебя сейчас

Сейчас:

catcher
 |
 HTTP

Разделить:

Было:
catcher.gleam
 State
 handle_message
 transport.send
Станет:
dispatcher.gleam


Message {
    SendEvent(Event)
}




worker.gleam


Message {
    Process(Event)
}
Отправка

hawk.send:

не ждёт HTTP:

hawk.send()
      |
      v
dispatcher mailbox


      |
      v


Ok(Nil)

То есть пользователь не тормозит.

Worker

А вот worker уже ждёт:

transport.send()


      |
      v


HTTP response


      |
      v


ack/log
Очередь

Важно: actor mailbox уже является очередью.

Не надо сразу писать свою очередь.

BEAM уже умеет:

messages:
[
 event1,
 event2,
 event3
]
Что бы я сделал сейчас по шагам:
Оставить твой catcher как будущий dispatcher.
Убрать из него HTTP.
Добавить worker.
Сделать hawk.send -> dispatcher.
Dispatcher делает actor.send(worker, event).
Worker вызывает transport.send.