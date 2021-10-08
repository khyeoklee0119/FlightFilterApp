%%%-------------------------------------------------------------------
%% @doc flightFilterApp public API
%% @end
%%%-------------------------------------------------------------------

-module(flightFilterApp_app).

-behaviour(application).

-export([start/2, stop/1]).
-include("record.hrl").

start(_StartType, _StartArgs) ->
  Dispatch = cowboy_router:compile([
    {'_', [{"/", augmentor_handler, []}]}
  ]),
  {ok, [IP, Port]} = application:get_env(?SERVER, http),
  {ok, _} = cowboy:start_clear(my_http_listener,
    [{ip, IP},
      {port, Port}],
    #{env => #{dispatch => Dispatch}}
  ),
  flightFilterApp_sup:start_link().

stop(_State) ->
  ok.

%% internal functions
