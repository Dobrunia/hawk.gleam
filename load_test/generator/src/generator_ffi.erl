-module(generator_ffi).
-export([now_ms/0, args/0]).

now_ms() ->
    erlang:monotonic_time(millisecond).

args() ->
    [list_to_binary(A) || A <- init:get_plain_arguments()].
