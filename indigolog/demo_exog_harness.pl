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
%% NOTE ON THE INTERPRETER HOOK: the official IndiGolog
%% distribution changed how simulated exogenous events are fed in
%% across versions (some expose exog_occurs/1, others read from a
%% scripted list via a "sim" environment manager, others prompt on
%% stdin). Two integration points are provided below -- keep
%% whichever one matches the interpreter installed on the course
%% VM and delete the other.
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
  assert(exog_script(2, hint_revealed(l_w2))),
  assert(exog_script(4, door_jams(r3,r4))),
  retractall(actions_done(_)),
  assert(actions_done(0)).

%% ------------------------------------------------------------
%% Call this once after every primitive action the agent executes
%% (hook this into the interpreter's action-execution callback,
%% e.g. exec_action/1 or similar, depending on the distribution).
%% It bumps the counter and fires any due scripted event.
%% ------------------------------------------------------------
notify_action_executed(A) :-
  prim_action(A), !,
  retract(actions_done(N)),
  N1 is N + 1,
  assert(actions_done(N1)),
  ( exog_script(N1, Exog)
  -> format("~n>>> [demo harness] injecting exogenous event: ~w~n", [Exog]),
     inject_exog(Exog)
  ;  true
  ).
notify_action_executed(_).

%% ------------------------------------------------------------
%% Integration point A: interpreters exposing exog_occurs/1 as a
%% hookable predicate (checked by the main loop between steps).
%% Uncomment if this matches your interpreter version.
%% ------------------------------------------------------------
% :- dynamic(pending_exog/1).
% inject_exog(E) :- assert(pending_exog(E)).
% exog_occurs([E]) :- retract(pending_exog(E)), !.
% exog_occurs([]).

%% ------------------------------------------------------------
%% Integration point B: interpreters that read simulated exogenous
%% events by asserting them directly as having occurred in the
%% current situation (older / simplified course distributions).
%% This is the default used below.
%% ------------------------------------------------------------
inject_exog(E) :-
  assertz(exog_happened(E)).

:- dynamic(exog_happened/1).

%% ------------------------------------------------------------
%% run_demo/0: convenience entry point for the live presentation.
%% Loosens the depth bound of the hard instance (a forced detour
%% around a jammed door is, by construction, longer than the
%% pure cost-optimal west-branch plan the PDDL/IndiGolog bound was
%% tuned for) and starts the Reactive Controller.
%% ------------------------------------------------------------
run_demo :-
  format("~n=== The Locked Archive -- live exogenous-event demo ===~n"),
  ( current_predicate(max_depth/1) -> retract(max_depth(_)) ; true ),
  assert(max_depth(35)),   % generous bound: base instance now needs up to 20
                           % (see instance_hard.pl), and a forced mid-plan
                           % reroute from a partially-explored west branch
                           % back to a full east branch needs extra slack
                           % on top of that.
  init_demo_script,
  initialize(evaluator),
  format("Starting Reactive Controller on the HARD instance...~n"),
  indigolog(control_reactive).
