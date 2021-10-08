-module(afs_client).

-export([start/0, stop/0, get_value/1]).

-define(INTEGER, 0).
-define(FLOAT, 1).

start() ->
    eredis_cluster:start().

stop() ->
    ok.

-spec get_value(string()) -> string().
get_value(Key) ->
    Result = eredis_cluster:q(["GET", Key]),
    case Result of
        {ok, Value} -> 
            Value;
        {_, _} ->
            undefined
    end.

%%-spec parse_value(string(), string(), string()) -> list().
%%parse_value(Value, Sep1="#", Sep2=",") ->
%%    L1 = re:split(Value, Sep1),
%%    L2 = lists:map(
%%        fun(X) ->
%%            re:split(X, Sep2)
%%        end, L1
%%    ),
%%    Json = make_test_json(),
%%    L3 = lists:map(
%%        fun(X) ->
%%            lists:map(
%%                fun(X1) ->
%%                    {Name, Type} = lists:nth(index_of(X1, X), Json),
%%                    X2 = binary_to_list(X1),
%%                    case Type of
%%                        ?INTEGER ->
%%                            Val = list_to_integer(X2);
%%                        ?FLOAT ->
%%                            Val = list_to_float(X2)
%%                    end,
%%                    {binary_to_list(Name), Val}
%%                end, X)
%%        end, L2),
%%    erlang:display(L3),
%%    L3.
%%
%%do_test() ->
%%    Value = get_value(<<"12-34-56">>),
%%    parse_value(Value, "#", ","),
%%    ok.
%%
%%make_test_json() ->
%%    List = jiffy:decode(<<"[{\"name\":\"campaignID\", \"type\":0},{\"name\":\"seg1\", \"type\":0},{\"name\":\"seg2\", \"type\":0},{\"name\":\"seg3\", \"type\":0},{\"name\":\"score1\", \"type\":1},{\"name\":\"score2\", \"type\":1},{\"name\":\"score3\", \"type\":1}]">>),
%%    [{N,T} || {[{<<"name">>, N}, {<<"type">>, T}]} <- List].
%%
%%index_of(Item, List) -> index_of(Item, List, 1).
%%index_of(_, [], _)  -> not_found;
%%index_of(Item, [Item|_], Index) -> Index;
%%index_of(Item, [_|Tl], Index) -> index_of(Item, Tl, Index+1).

%%-spec set_afs_client_env(list()) -> term().
%%set_afs_client_env(Config) ->
%%    {pool_size, Pool_size} = lists:nth(2, Config),
%%    application:set_env(eredis_cluster, pool_size, Pool_size),
%%
%%    {pool_max_overflow, Pool_max_overflow} = lists:nth(3, Config),
%%    application:set_env(eredis_cluster, pool_max_overflow, Pool_max_overflow),
%%
%%    {socket_options, [{send_timeout, Send_timeout}]} = lists:nth(4, Config),
%%    application:set_env(eredis_cluster, socket_options, [{send_timeout, Send_timeout}]),
%%
%%    %% Set initial nodes and perform a controlled connect
%%    {init_nodes, Nodes} = lists:nth(1, Config),
%%    if
%%        length(Nodes) > 0 ->
%%            eredis_cluster:connect(Nodes),
%%            ok;
%%        true ->
%%            failed
%%    end.
%%


