%%%-------------------------------------------------------------------
%%% @author khyeoklee
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Oct 2021 오후 3:09
%%%-------------------------------------------------------------------
-module(utils).
-author("khyeoklee").

%% API
-export([fast_lookup/3]).

fast_lookup(Key, List, Default) ->
  case lists:keyfind(Key, 1, List) of
    false -> Default;
    {_, Value} -> Value
  end.