%% ============================================================
%% The Locked Archive -- Live presentation harness
%%
%% Feeds a small SCRIPTED sequence of exogenous events into a run
%% of control_reactive on the HARD instance, to show the Reactive
%% Controller adapting on the fly:
%%
%%   1. hint_revealed(l_w2)  -- fired after 2 world actions.
%%      known_code(l_w2) becomes true immediately (see
%%      escape_room_domain.pl); the reactive controller's next
%%      offline one-step search simply never proposes
%%      read_clue(l_w2,r3) again, because unlock_with_code(l_w2)
%%      is already legal. No special-case code is needed for this
%%      -- it falls straight out of the successor state axiom.
%%
%%   2. door_jams(r3,r4)     -- fired after 4 world actions.
%%      blocked(r3,r4) and blocked(r4,r3) become true; poss/2 for
%%      move(r3,r4,l_w2) (and the reverse) becomes false. The next
%%      reactive one-step search can no longer complete the west
%%      branch, backtracks to r2, and instead opens the east
%%      branch (l_e1 / l_e2 / l_e3) to reach r8.
%%
%% CONFIRMED interpreter hook (from the course's own elevator_01.pl /
%% elevator_02.pl lab files): the interpreter calls exog_occurs(A)
%% after every primitive action.
%%   - "Nothing happened" = exog_occurs(A) FAILS (not "succeeds with
%%     []" -- that was an earlier, wrong guess before these lab
%%     files were available).
%%   - "Something happened" = exog_occurs(A) SUCCEEDS with A bound
%%     to the single exogenous action that occurred.
%% We piggyback the action counter directly on this call (it is
%% invoked exactly once per world action by the interpreter's own
%% loop), so no separate "notify after each action" hook is needed.
%% ============================================================

:- dynamic(exog_script/2).     % exog_script(TriggerActionCount, ExogAction)
:- dynamic(actions_done/1).

%% ------------------------------------------------------------
%% The script for this demo. TriggerActionCount = number of
%% PRIMITIVE world actions already executed by the agent when the
%% event should fire.
%% ------------------------------------------------------------
init_demo_script :-
  retractall(exog_script(_,_)),
  assertz(exog_script(2, hint_revealed(l_w2))),
  assertz(exog_script(4, door_jams(r3,r4))),
  retractall(actions_done(_)),
  assertz(actions_done(0)),
  %% Replace the base "exog_occurs(_) :- fail." fallback from
  %% escape_room_domain.pl with the scripted version, in the right
  %% clause order (specific case first, so it isn't shadowed).
  retractall(exog_occurs(_)),
  assertz((exog_occurs(A) :-
             retract(actions_done(N)),
             N1 is N + 1,
             assertz(actions_done(N1)),
             exog_script(N1, A),
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
%%   ?- ['demo_exog_harness.pl'].
%%   ?- run_demo.
%% ------------------------------------------------------------
