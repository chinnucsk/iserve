-module(iserve).
-export([create_table/1,
         add_callback/5, delete_callback/3,
         print_callbacks/0,lookup/3]).

-record(iserve_callback, {key,                 % {Port, 'GET'|'POST', Abs_path}
                          mf}).                % {Mod, Func}

create_table(_Nodes) ->
    mnesia:start(),
    mnesia:create_table(iserve_callback,[
        {attributes, record_info(fields, iserve_callback)}
    ]).

lookup(Port, Method, Path) ->
    case ets:lookup(iserve_callback, {Port, Method, Path}) of
        [#iserve_callback{mf = {Mod, Func}}] ->
            {ok, Mod, Func};
        [] ->
            {error, not_found}
    end.

add_callback(Port, Method, Path, Mod, Func) when ((Method == 'GET') or (Method == 'POST') and
                                                  is_list(Path) and is_atom(Mod) and
                                                  is_atom(Func) and is_integer(Port)) ->
    mnesia:dirty_write(iserve_callback, #iserve_callback{key = {Port, Method, Path}, mf = {Mod, Func}}).


delete_callback(Port, Method, Path) ->
    mnesia:dirty_delete(iserve_callback, {Port, Method, Path}).

print_callbacks() ->
    All = mnesia:dirty_match_object(#iserve_callback{_ = '_'}),
    io:format("Port\tMethod\tPath\tModule\tFunction~n"),
    lists:foreach(fun(#iserve_callback{key = {Port, Method, Path}, mf = {Module, Function}}) ->
        io:format("~p\t~p\t~p\t~p\t~p\r\n",[Port, Method, Path, Module, Function])
    end, All).
