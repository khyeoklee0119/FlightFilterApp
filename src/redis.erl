%%%-------------------------------------------------------------------
%%% @author khyeoklee
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2021 오후 3:07
%%%-------------------------------------------------------------------
-module(redis).
-author("khyeoklee").

%% API
-export([start/0, query/1]).

start() ->
  afs_client:start().

query(Key) ->
  case afs_client:get_value(Key) of
    undefined ->
      {error, no_redis_value};
    Value ->
      io:format("Redis ~p : ~p ~n",[Key,Value]),
      {ok, Value}
  end.
