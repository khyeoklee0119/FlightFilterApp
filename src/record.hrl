%%%-------------------------------------------------------------------
%%% @author khyeoklee
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2021 오후 3:02
%%%-------------------------------------------------------------------
-author("khyeoklee").
-define(CONFIG_ML_SEGMENT, <<"MLSegment">>).
-define(CONFIG_ML_SEGMENT_LOAS_CLUSTER, <<"roas_cluster">>).
-define(CONFIG_LOOKALIKE, <<"LAL">>).
-define(CONFIG_LOOKALIKE_SCORE,
  CONFIG_LOOKALIKE_SCORE_SCORE_A|
  CONFIG_LOOKALIKE_SCORE_SCORE_B).
-define(CONFIG_LOOKALIKE_SCORE_SCORE_A, <<"scoreA">>).
-define(CONFIG_LOOKALIKE_SCORE_SCORE_B, <<"scoreB">>).
-define(CONFIG_LOOKALIKE_DEFAULT_THRESHOLD, <<"default_threshold">>).
-define(CONFIG_LOOKALIKE_THRESHOLD_BY_CAMPAIGN, <<"threshold_by_campaign">>).
-define(LOOKUP(Key, List), ?LOOKUP(Key, List, undefined)).
-define(LOOKUP(Key, List, Default), utils:fast_lookup(Key, List, Default)).
-define(SERVER, flightFilterApp).

-record(afs_data, {
  campaignID :: number(),
  scoreA :: float(),
  scoreB :: float(),
  roasCluster :: integer(),
  targeted :: boolean()
}).
-record(bid_device, {
  ifa :: undefined | binary()
}).
-record(bid_req, {
  device :: undefined | #bid_device{}
}).


-record(flight, {
  flight_id :: integer(),
  campaign_id :: integer()
}).

-record(checker_state, {
  afsdata_list :: list(),
  lal_thresholds :: list(),
  segment_thresholds :: list()
}).

-record(threshold, {
  default_threshold :: float(),
  threshold_by_campaign :: [{integer(), float()}] | undefined
}).

-record(augmentor_config, {
  lal_score :: any(),
  ml_segment :: any()
}).
