# Архитектура

## INIT

```
hawk.init(token)
    ↓
otp/root_supervisor          static, OneForAll
    ├── otp/worker_supervisor    factory, пока пустая
    └── otp/dispatcher
            │  start_child ×2
            ↓
        otp/http_worker          под factory
            └── transport
```

Root поднимает factory, потом dispatcher. Dispatcher в initialiser просит factory на двух worker’ов. Supervisor дальше в send не участвует.

## SEND

ещё не в публичном API (`hawk.send` = `todo`), путь внутри dispatcher уже такой:

```
hawk.send(payload)
    ↓
dispatcher                     Enqueue
    ↓
валидация → Event
    ↓
свободный worker? ──да──→ http_worker     ProcessEvent
         │                      ↓
         нет                 transport.send
         ↓                      ↓
      pending                WorkerReady
         │                      │
         └──────── берёт следующий из pending, если есть
```

`send` кладёт в mailbox dispatcher’а и сразу возвращается. HTTP ждёт только worker.
