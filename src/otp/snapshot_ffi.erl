-module(snapshot_ffi).
-export([get_snapshot/0, put_snapshot/1, new_user_id/0]).

-define(KEY, hawk_gleam_dispatcher_snapshot_v2).

get_snapshot() ->
    try persistent_term:get(?KEY) of
        Snapshot -> {ok, Snapshot}
    catch
        error:badarg -> {error, nil}
    end.

put_snapshot(Snapshot) ->
    persistent_term:put(?KEY, Snapshot),
    nil.

new_user_id() ->
    Integer = erlang:unique_integer([positive]),
    iolist_to_binary(["user-", integer_to_binary(Integer)]).
