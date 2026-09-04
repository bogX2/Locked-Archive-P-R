%% ============================================================
%% The Locked Archive -- Main entry point, EASY instance.
%%
%% Usage (from a directory containing the official IndiGolog
%% interpreter, e.g. on the course VM):
%%
%%   ?- [indigolog].            % load the IndiGolog interpreter
%%   ?- [main_easy].            % load domain + this instance
%%   ?- initialize(evaluator).  % MANDATORY before any execution --
%%                               % skipping this call is the single
%%                               % most common cause of "undefined
%%                               % procedure" errors when a fresh
%%                               % run is started.
%%   ?- indigolog(control_simple).
%%   ?- indigolog(control_reactive).
%% ============================================================

:- ['escape_room_domain.pl'].
:- ['controllers.pl'].
:- ['instances/instance_easy.pl'].
