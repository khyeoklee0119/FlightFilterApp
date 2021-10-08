-module(augmentor_handler).
-behavior(cowboy_handler).

-export([init/2]).
-include("record.hrl").

init(Req0, State) ->
  case cowboy_req:method(Req0) of
    <<"PUT">> ->
      gen_server:cast(augmentor, {update_config}),
      Req = cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/plain">>},
        <<"OK! Done with updating">>,
        Req0),
      {ok, Req, State};

    _ ->
      {ok, Data, _} = cowboy_req:read_body(Req0),
      Body = jiffy:decode(Data),
      BidReq = make_bid_request(Body),
      Flights = example_flights(),
      case gen_server:call(augmentor, {filter, BidReq, Flights}) of
        {ok, Result} ->
          Res= io_lib:format("Before : ~p ~nAfter: ~p ~n",[Flights, Result]),
          io:fwrite("===============~n~s===============~n",[Res]),
          Req = cowboy_req:reply(200,
            #{<<"content-type">> => <<"text/plain">>},
            Res,
            Req0);
        {error, Reason} ->
          Res= io_lib:format("(~p) no filtering has been done~n~p~n",[Reason, Flights]),
          Req = cowboy_req:reply(200,
            #{<<"content-type">> => <<"text/plain">>},
            Res,
            Req0)

      end,
      {ok, Req, State}
  end.


example_flights() ->
  Flights = [#flight{flight_id = X, campaign_id = X} || X <- lists:seq(0, 4)],
  Flights.

make_bid_request({Body}) ->
  #bid_req{
    device = make_device(?LOOKUP(<<"device">>, Body))
  }.

make_device({Device}) ->
  #bid_device{
    ifa = ?LOOKUP(<<"ifa">>, Device)
  }.
