%%%-------------------------------------------------------------------
%% @doc flightFilterApp top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(flightFilterApp_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).
-include("record.hrl").

start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
  SupFlags = #{strategy => one_for_one,
    intensity => 1,
    period => 5},
  AugSpec = case application:get_env(?SERVER, augmentor) of
              {ok, AugConfig} ->
                [{augmentor,
                  {augmentor, start_link, [AugConfig]},
                  permanent, 1000, worker, [augmentor]}];
              _ -> []
            end,
  ChildSpecs = AugSpec,
  {ok, {SupFlags, ChildSpecs}}.

%% internal functions
