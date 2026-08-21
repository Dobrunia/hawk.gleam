-module(logger_ffi).
-export([println/1]).

println(Text) ->
    try io:put_chars([Text, $\n]) of
        _ -> nil
    catch
        _:_ -> nil
    end.
