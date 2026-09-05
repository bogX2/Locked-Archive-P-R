%% ============================================================
%% The Locked Archive -- Live presentation harness
%%
%% SIMPLIFIED DESIGN: both scripted exogenous events fire
%% IMMEDIATELY, before the agent takes a single real action --
%% not mid-plan. This is a deliberate simplification: this course
%% interpreter (indigolog_plain.pl) has no gexec/unset (confirmed
%% absent from both its own source and lib/common.pl), which is
%% what sokoban.pl/taxi.pl/elevator.pl rely on to gracefully abort
%% and restart a search mid-execution when the world changes.
%% Reproducing that gracefully turned out to require either (a)
%% relaxing the anti-cycle guard, which made the search wander
%% indefinitely once fully unlocked (confirmed: it explored
%% pointless bounces and even moves OUT of the already-reached exit
%% room), or (b) accepting a controller that cannot always recover
%% from being deep inside a now-blocked corridor -- a genuine
%% limitation of a purely single-action-reactive design without
%% gexec-style abortable execution.
%%
%% Firing events at the very start instead sidesteps this cleanly:
%% indigolog_plain.pl's own indigo/2 loop checks exog_occurs/1
%% BEFORE every attempted transition ("indigo(E,H) :-
%% once(exog_occurs(Act)), exog_action(Act), !, indigo(E,[Act|H])."),
%% including the very first one -- so any queued events are fully
%% incorporated into the situation before search(escape_task) is
%% ever invoked. The Reactive Controller then plans directly around
%% the now-permanently-blocked west branch from a clean start,
%% still genuinely demonstrating both mechanisms:
%%
%%   1. hint_revealed(l_e2) -- known_code(l_e2) becomes true
%%      immediately; the plan found will never include
%%      read_clue(l_e2,r6), going straight to unlock_with_code(l_e2)
%%      -- this falls straight out of the successor state axiom, no
%%      special-case code needed.
%%
%%   2. door_jams(r2,r3) -- blocks the west branch entirely from the
%%      first step; search(escape_task) finds a plan through the
%%      east branch (r2->r6->r7->r8) instead, since the west route
%%      is simply never explorable to begin with.
%%
%% CONFIRMED interpreter hook (course lab files elevator_01.pl /
%% elevator_02.pl): exog_occurs(A) FAILS when nothing happens,
%% SUCCEEDS with A bound to the occurring action otherwise.
%% ============================================================

:- dynamic(pending_exog/1).

%% ------------------------------------------------------------
%% The two events to fire, in order, before any real action.
%% ------------------------------------------------------------
init_demo_script :-
  retractall(pending_exog(_)),
  assertz(pending_exog(hint_revealed(l_e2))),
  assertz(pending_exog(door_jams(r2,r3))),
  %% Replace the base "exog_occurs(_) :- fail." fallback from
  %% escape_room_domain.pl with the scripted version, in the right
  %% clause order (drain the queue first, then fail forever).
  retractall(exog_occurs(_)),
  assertz((exog_occurs(A) :-
             retract(pending_exog(A)), !,
             format("~n>>> [demo harness] injecting exogenous event: ~w~n", [A]))),
  assertz((exog_occurs(_) :- fail)).

%% ------------------------------------------------------------
%% run_demo/0: convenience entry point for the live presentation.
%% ------------------------------------------------------------
run_demo :-
  format("~n=== The Locked Archive -- live exogenous-event demo ===~n"),
  init_demo_script,
  initialize,              % NOT initialize(evaluator) -- confirmed on the
                           % course VM's indigolog_plain: it's arity 0.
  format("Starting Reactive Controller on the HARD instance...~n"),
  indigolog(control_reactive).

%% ------------------------------------------------------------
%% Usage (after config.pl + main_hard.pl already loaded):
%%   ?- ['indigolog/demo_exog_harness.pl'].
%%   ?- run_demo.
%% ------------------------------------------------------------