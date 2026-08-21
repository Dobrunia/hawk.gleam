-module(dispatcher_ffi).
-export([process_metrics/1]).

process_metrics(Pid) ->
    {
        info_value(Pid, message_queue_len),
        info_value(Pid, memory),
        info_value(Pid, reductions)
    }.

info_value(Pid, Key) ->
    case process_info(Pid, Key) of
        {Key, Value} -> Value;
        undefined -> 0
    end.
