-module(generator_ffi).
-export([
    now_ms/0,
    unix_microseconds/0,
    runtime_ms/0,
    wall_clock_ms/0,
    memory_bytes/0,
    collector_reset/0,
    collector_stats/0,
    args/0
]).

-define(COLLECTOR, "http://127.0.0.1:8787").

now_ms() ->
    erlang:monotonic_time(millisecond).

unix_microseconds() ->
    erlang:system_time(microsecond).

runtime_ms() ->
    element(1, erlang:statistics(runtime)).

wall_clock_ms() ->
    element(1, erlang:statistics(wall_clock)).

memory_bytes() ->
    erlang:memory(total).

collector_reset() ->
    ensure_inets(),
    Request = {?COLLECTOR ++ "/reset", [], "text/plain", <<>>},
    case httpc:request(
        post,
        Request,
        [{timeout, 5000}],
        [{body_format, binary}]
    ) of
        {ok, {{_Version, Status, _Reason}, _Headers, _Body}}
            when Status >= 200, Status < 300 ->
            {ok, nil};
        _ ->
            {error, nil}
    end.

collector_stats() ->
    ensure_inets(),
    case httpc:request(
        get,
        {?COLLECTOR ++ "/stats", []},
        [{timeout, 5000}],
        [{body_format, binary}]
    ) of
        {ok, {{_Version, Status, _Reason}, _Headers, Body}}
            when Status >= 200, Status < 300 ->
            {ok, Body};
        _ ->
            {error, nil}
    end.

ensure_inets() ->
    application:ensure_all_started(inets).

args() ->
    [list_to_binary(A) || A <- init:get_plain_arguments()].
