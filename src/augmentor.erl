%%%-------------------------------------------------------------------
%%% @author khyeoklee
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2021 오후 3:37
%%%-------------------------------------------------------------------
-module(augmentor).
-author("khyeoklee").
-include("record.hrl").
-behaviour(gen_server).
%% API
-export([start_link/1, filter/3, init/1, handle_call/3, handle_cast/2]).

start_link(Config) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, Config,[]).

%% Todo Get path of config from system evn
init(Config) ->
  erlang:display(Config),
  ConfigFilePath = ?LOOKUP(config,Config),
  configure(ConfigFilePath).

configure(FilePath) ->
  case file:read_file(FilePath) of
    {ok, Text} ->
      Json = jiffy:decode(Text),
      Config = parse_config(Json),
      {ok, Config};
    {error, Reason} ->
      io:format(Reason),
      {stop, Reason}
  end.

handle_call({filter, #bid_req{} = BidRequest, Flights}, _From, #augmentor_config{} = State) ->
  Reply = augmentor:filter(BidRequest, Flights, State),
  {reply, Reply, State};
handle_call(_Request, _From, _State) ->
  erlang:error(not_implemented).

handle_cast({update_config}, State) ->
  io:format("start to update config "),
  case configure("./src/augmentor_config.json") of
    {ok, Config} -> {noreply, Config};
    {_, _} -> {noreply, State}
  end;
handle_cast(_Request, _State) ->
  erlang:error(not_implemented).

-spec filter(#bid_req{}, list(#flight{}), #augmentor_config{}) ->
  {ok, list(#flight{})} | {error, any()}.
filter(#bid_req{
  device = #bid_device{
    ifa = UserID
  }
}, Flights, AugmentorConfig) ->
  case redis:query(UserID) of
    {ok, Binary} ->
      Sources = string:split(Binary, ",", all),
      case decode(Sources, []) of
        {ok, AFSDataList} ->
          io:format("Decoded to AFSData ~p~n",[AFSDataList]),
          FilteringFun = [
            fun filter_scoreA/1,
            fun filter_scoreB/1,
            fun filter_roas_cluster/1
          ],
          TargetAFSDataList = query_checkers(FilteringFun, AFSDataList, AugmentorConfig),
          DetargetAFSDataList = lists:filter(fun(AFSData) -> AFSData#afs_data.targeted =/= true end, TargetAFSDataList),
          Result = remove_if_contains(Flights, DetargetAFSDataList),
          {ok, Result};
        {error, Reason} ->
          io:format("!!!!! Illega format ~p~n",[Reason]),
          {error, Reason}
      end;
    {error, Reason} ->
      io:format("!!!!!!!! ~p for User in Redis~n", [Reason]),
      {error, Reason}
  end.

query_checkers(Checkers, AFSDataList, #augmentor_config{lal_score = LAL, ml_segment = MLSegments}) ->
  CheckerState = #checker_state{
    afsdata_list = AFSDataList,
    lal_thresholds = LAL,
    segment_thresholds = MLSegments
  },
  Check = fun(Checker, Acc) ->
    Checker(Acc)
          end,
  Result = lists:foldl(Check, CheckerState, Checkers),
  Result#checker_state.afsdata_list.

decode([<<"v1">> | Data], AFSDataList) ->
  decoder_v1:decode(Data, AFSDataList);
decode(_, _) ->
  io:format("Illegal format"),
  {error, illegal_format}.

filter_roas_cluster(#checker_state{afsdata_list = AFSDataList, segment_thresholds = SegmentThresholds} = State) ->
  Threshold = lookup_threshold(?CONFIG_ML_SEGMENT_LOAS_CLUSTER, SegmentThresholds, []),
  FilteredAFS = lists:map(fun(#afs_data{campaignID = CampaignID, roasCluster = RoasCluster} = AFSData) ->
    case lists:keyfind(CampaignID, 1, Threshold) of
      {_, TargetSegmentList} ->
        case (length(TargetSegmentList) =:= 0) or lists:member(RoasCluster, TargetSegmentList) of
          true ->
            AFSData#afs_data{targeted = true};
          false ->
            AFSData
        end;
      _ -> AFSData#afs_data{targeted = true}
    end
                          end, AFSDataList),
  State#checker_state{afsdata_list = FilteredAFS}.

filter_scoreA(#checker_state{afsdata_list = AFSDataList, lal_thresholds = Thresholds} = State) ->
  Threshold = lookup_threshold(?CONFIG_LOOKALIKE_SCORE_SCORE_A, Thresholds, #threshold{default_threshold = 1.1}),
  FilteredAFS = lists:map(fun(#afs_data{campaignID = CampaignID, scoreA = Score} = AFSData) ->
    #threshold{
      default_threshold = DefaultThreshold,
      threshold_by_campaign = ThresholdByCam
    } = Threshold,
    FinalThreshold = lookup_threshold(CampaignID, ThresholdByCam, DefaultThreshold),
    if
      Score >= FinalThreshold ->
        AFSData#afs_data{targeted = true};
      true -> AFSData
    end
                          end, AFSDataList),
  State#checker_state{
    afsdata_list = FilteredAFS
  }.

filter_scoreB(#checker_state{afsdata_list = AFSDataList, lal_thresholds = Thresholds} = State) ->
  Threshold = lookup_threshold(?CONFIG_LOOKALIKE_SCORE_SCORE_B, Thresholds, #threshold{default_threshold = 1.1}),
  FilteredAFS = lists:map(fun(#afs_data{campaignID = CampaignID, scoreB = Score} = AFSData) ->
    #threshold{
      default_threshold = DefaultThreshold,
      threshold_by_campaign = ThresholdByCam
    } = Threshold,
    FinalThreshold = lookup_threshold(CampaignID, ThresholdByCam, DefaultThreshold),
    if
      Score >= FinalThreshold ->
        AFSData#afs_data{targeted = true};
      true -> AFSData
    end
                          end, AFSDataList),
  State#checker_state{
    afsdata_list = FilteredAFS
  }.

lookup_threshold(Key, Thresholds, Default) when is_list(Thresholds) ->
  case lists:keyfind(Key, 1, Thresholds) of
    {Key, Value} -> Value;
    _ -> Default
  end;
lookup_threshold(_, _, Default) ->
  Default.


parse_config({Config}) ->
  LALExtractor = fun({Key, {Threshold}}) ->
    ThresholdsByCam = make_threshold_by_cam(?LOOKUP(?CONFIG_LOOKALIKE_THRESHOLD_BY_CAMPAIGN, Threshold)),
    {Key, #threshold{
      default_threshold = ?LOOKUP(?CONFIG_LOOKALIKE_DEFAULT_THRESHOLD, Threshold),
      threshold_by_campaign = ThresholdsByCam
    }} end,
  case ?LOOKUP(?CONFIG_LOOKALIKE, Config) of
    {LALConfig} ->
      LAL = lists:map(LALExtractor, LALConfig);
    undefined ->
      LAL = []
  end,

  MLSegmentExtractor = fun({Key, {SegmentsByFlight}}) ->
    MLSegmentByFlightID = lists:map(fun({FlightID, SegmentNumber})
      -> {binary_to_integer(FlightID), SegmentNumber} end, SegmentsByFlight),
    {Key, MLSegmentByFlightID}
                       end,
  case ?LOOKUP(?CONFIG_ML_SEGMENT, Config) of
    {MLSegmentConfig} ->
      MLSegment = lists:map(MLSegmentExtractor, MLSegmentConfig);

    undefined -> MLSegment = []
  end,
  #augmentor_config{
    lal_score = LAL,
    ml_segment = MLSegment
  }.

make_threshold_by_cam({Raw}) when is_list(Raw) ->
  lists:map(fun({ID, Threshold}) -> {binary_to_integer(ID), Threshold} end, Raw);
make_threshold_by_cam(_Raw) ->
  undefined.

remove_if_contains(Flights, DetargetCampaigns) ->
  DetargetCampaignIDs = [ID || #afs_data{campaignID = ID} <- DetargetCampaigns],
  lists:filter(fun(#flight{campaign_id = CampaignID}) ->
    lists:member(CampaignID, DetargetCampaignIDs) =:= false end, Flights).
