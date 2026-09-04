%% ============================================================
%% The Locked Archive -- Main entry point, HARD instance.
%% See main_easy.pl for the standard load/run sequence.
%%
%% This instance is the one to use for the live presentation demo
%% together with demo_exog_harness.pl, since it is the only one
%% with two branches to reroute between when door_jams fires.
%% ============================================================

:- ['escape_room_domain.pl'].
:- ['controllers.pl'].
:- ['instances/instance_hard.pl'].
