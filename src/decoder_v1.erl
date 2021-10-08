%%%-------------------------------------------------------------------
%%% @author khyeoklee
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2021 오후 2:43
%%%-------------------------------------------------------------------
-module(decoder_v1).
-author("khyeoklee").
%% API
-export([decode/2]).
-include("record.hrl").

-define(TOTAL_ELEM, 4).
-define(IDX_CAMPAIGN, 1).
-define(IDX_SCORE_A, 2).
-define(IDX_SCORE_B, 3).
-define(IDX_ROAS_CLUSTER, 4).

decode([], AFSDataList) ->
  {ok, AFSDataList};
decode(Data, AFSDataList) when is_list(Data) ->
  {SourceList, Rest} = lists:split(?TOTAL_ELEM, Data),
  ID = bin_to_integer(lists:nth(?IDX_CAMPAIGN, SourceList)),
  ScoreA = bin_to_float(lists:nth(?IDX_SCORE_A, SourceList)),
  ScoreB = bin_to_float(lists:nth(?IDX_SCORE_B, SourceList)),
  RoasCluster = bin_to_integer(lists:nth(?IDX_ROAS_CLUSTER, SourceList)),
  NewAFSData = #afs_data{campaignID = ID, scoreA = ScoreA, scoreB = ScoreB, roasCluster = RoasCluster},
  decode(Rest, [NewAFSData|AFSDataList]);
decode(_, _) ->
  io:format("Illegal format"),
  {error, illegal_format}.

bin_to_float(Bin) ->
  N = binary_to_list(Bin),
  case string:to_float(N) of
    {error, no_float} -> 0.0;
    {F, _Rest} -> F
  end.

bin_to_integer(Bin) ->
  N = binary_to_list(Bin),
  case string:to_integer(N) of
    {error, no_integer} -> -1;
    {I, _Rest} -> I
  end.