%%%-------------------------------------------------------------------
%%% @author Wade Mealing <wmealing@Wades-MacBook-Pro.local>
%%% @copyright (C) 2013, Wade Mealing
%%% @doc
%%%
%%% @end
%%% Created : 27 Jun 2013 by Wade Mealing <wmealing@Wades-MacBook-Pro.local>
%%%-------------------------------------------------------------------
-module(producer).

-include_lib("./deps/gen_bunny/include/gen_bunny.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-export([send_message/1]).

-define(SERVER, ?MODULE). 

-record(state, {pid}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    Exchange =  #'exchange.declare'{exchange = <<"fanout">>, type= <<"fanout">>, durable=true},
    DeclareInfo = {Exchange},
    {ok, Pid} = bunnyc:start_link(mq_producer,
                    {network, "localhost", 5672, {<<"guest">>, <<"guest">>}, <<"/">>},
                    DeclareInfo,
                    [] ),
    {ok, #state{pid=Pid}}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call({send_message, Msg}, _From, State) when is_list(Msg) ->
    BinMsg = list_to_binary(Msg),
    bunnyc:publish(mq_producer, <<"myqueue">>, BinMsg),
    Reply = ok,
    {reply, Reply, State};

handle_call({send_message, Msg}, _From, State) when is_binary(Msg) ->
    bunnyc:publish(mq_producer, <<"myqueue">>, Msg),
    Reply = ok,
    {reply, Reply, State};

handle_call(Request, _From, State) ->
    io:format("Producer Request is: ~p~n", [Request]),
    {reply, ok, State}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

send_message(Msg) ->
    gen_server:call(?MODULE , {send_message, Msg }).

