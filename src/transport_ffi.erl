-module(transport_ffi).
-export([configure/1, send/2]).

-define(PROFILE, hawk_gleam).

configure(Limit) when is_integer(Limit), Limit > 0 ->
    case application:ensure_all_started(inets) of
        {ok, _} ->
            configure_profile(Limit);
        {error, _} ->
            {error, nil}
    end.

configure_profile(Limit) ->
    case ensure_profile() of
        ok ->
            Options = connection_options(Limit),
            case httpc:set_options(Options, ?PROFILE) of
                ok -> {ok, nil};
                {error, _} -> {error, nil}
            end;
        {error, _} ->
            {error, nil}
    end.

ensure_profile() ->
    case inets:start(httpc, [{profile, ?PROFILE}]) of
        {ok, _Pid} -> ok;
        {error, {already_started, _Pid}} -> ok;
        Error -> Error
    end.

connection_options(Limit) ->
    Base = [{max_sessions, Limit}],
    case list_to_integer(erlang:system_info(otp_release)) >= 29 of
        true -> [{max_connections_open, Limit} | Base];
        false -> Base
    end.

send(Url, Body) ->
    Request = {
        binary_to_list(Url),
        [{"user-agent", "hawk_gleam/1.0"}],
        "application/json",
        Body
    },
    HttpOptions = [{timeout, 30000}, {connect_timeout, 5000}],
    RequestOptions = [{body_format, binary}],
    case httpc:request(
        post,
        Request,
        HttpOptions,
        RequestOptions,
        ?PROFILE
    ) of
        {ok, {{_Version, Status, _Reason}, _Headers, _ResponseBody}} ->
            {ok, Status};
        {error, _} ->
            {error, nil}
    end.
