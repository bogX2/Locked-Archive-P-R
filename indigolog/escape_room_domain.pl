%% ============================================================
%% The Locked Archive -- Escape Room Solver
%% Situation Calculus action theory (Reiter-style), written for
%% the official IndiGolog interpreter (University of Toronto).
%%
%% Load order expected by main_*.pl:
%%   1. IndiGolog interpreter files (indigolog.pl, lp.pl, etc.)
%%   2. this file (escape_room_domain.pl)
%%   3. one instance_*.pl file (initial situation + map layout)
%%   4. call: initialize(evaluator), then run a main procedure.
%% ============================================================

:- discontiguous(prim_action/1).
:- discontiguous(poss/2).
:- discontiguous(causes_true/3).
:- discontiguous(causes_false/3).

%% ------------------------------------------------------------
%% Mandatory IndiGolog boilerplate.
%% Without these two declarations the interpreter's evaluator
%% throws existence errors on the very first transition -- this
%% cost real debugging time, so it is kept explicit and commented
%% here rather than left implicit.
%% ------------------------------------------------------------
fun_fluent(_) :- fail.
cache(_) :- fail.

%% ------------------------------------------------------------
%% Relational fluents (mirror the PDDL predicates).
%%
%% All declared dynamic: the real interpreter's projector
%% (eval_bat.pl) evaluates holds(F, []) by calling F directly as a
%% plain Prolog goal. Instance files only state facts for fluents
%% that are TRUE in s0 (closed-world assumption for the rest) --
%% without "dynamic", calling e.g. unlocked(l1) when NO unlocked/1
%% fact exists anywhere throws "Unknown procedure" instead of just
%% failing. Declaring dynamic makes an absent fact correctly mean
%% "false" rather than a hard error.
%% ------------------------------------------------------------
:- dynamic(at/1).
:- dynamic(has/1).
:- dynamic(item_at/2).
:- dynamic(unlocked/1).
:- dynamic(known_code/1).
:- dynamic(blocked/2).
:- dynamic(depth_used/1).

rel_fluent(at(_)).            % at(Room)          -- agent's current room
rel_fluent(has(_)).           % has(Item)         -- agent carries Item
rel_fluent(item_at(_,_)).     % item_at(Item,Room)
rel_fluent(unlocked(_)).      % unlocked(Lock)
rel_fluent(known_code(_)).    % known_code(Lock)
rel_fluent(blocked(_,_)).     % blocked(R1,R2)    -- door temporarily jammed
rel_fluent(depth_used(_)).    % depth_used(N)     -- move counter, for depth bounding

%% ------------------------------------------------------------
%% Static (world-map) relations -- plain facts, not fluents.
%% Declared per instance file: connected/3, needs_key/2,
%% combinable/3, clue_at/2, key_lock/1, code_lock/1, room/1,
%% item/1, exit_room/1. max_depth/1 is also per-instance, declared
%% dynamic here so demo_exog_harness.pl can safely retract/reassert
%% it with a looser bound for the live exogenous-event demo.
%% ------------------------------------------------------------
:- dynamic(max_depth/1).

%% ------------------------------------------------------------
%% Primitive (world) actions.
%% ------------------------------------------------------------
prim_action(move(_,_,_)).            % move(From,To,Lock)
prim_action(pick_up(_,_)).           % pick_up(Item,Room)
prim_action(combine(_,_,_)).         % combine(Item1,Item2,Item3)
prim_action(read_clue(_,_)).         % read_clue(Lock,Room)
prim_action(unlock_with_key(_,_)).   % unlock_with_key(Lock,Item)
prim_action(unlock_with_code(_)).    % unlock_with_code(Lock)

%% ------------------------------------------------------------
%% Exogenous actions (environment-driven events, not chosen by
%% the agent's program). See demo_exog_harness.pl for how these
%% are injected during a live run.
%% ------------------------------------------------------------
exog_action(hint_revealed(_)).       % hint_revealed(Lock) -- code learned early
exog_action(door_jams(_,_)).         % door_jams(R1,R2)    -- a door becomes blocked

%% ------------------------------------------------------------
%% Action precondition axioms: poss(Action, Condition)
%% ------------------------------------------------------------
poss(move(R1,R2,L), and(at(R1),
                     and(connected(R1,R2,L),
                     and(unlocked(L),
                     and(neg(blocked(R1,R2)),
                         neg(depth_exhausted)))))).

poss(pick_up(I,R), and(at(R), item_at(I,R))).

poss(combine(I1,I2,I3), and(has(I1), and(has(I2), combinable(I1,I2,I3)))).

poss(read_clue(L,R), and(at(R), clue_at(L,R))).

poss(unlock_with_key(L,I), and(needs_key(L,I), has(I))).

poss(unlock_with_code(L), known_code(L)).

%% exogenous events are always possible for the environment to fire
poss(hint_revealed(_), true).
poss(door_jams(_,_), true).

%% ------------------------------------------------------------
%% exog_occurs/1: MANDATORY interpreter hook. indigolog_plain's
%% online execution loop calls this after every action to check
%% whether any exogenous event has occurred in the "real world"
%% and should be incorporated before the next step. With no live
%% event source connected, we simply report "nothing happened" --
%% this is what lets control_simple / control_reactive run without
%% external input. Declared dynamic so demo_exog_harness.pl can
%% cleanly REPLACE this fallback (retractall + reassert in the
%% correct clause order) to script hint_revealed/door_jams for the
%% live presentation demo, instead of just adding a clause after
%% it (which would never be reached, since this trivial "always []"
%% clause would match first).
%% ------------------------------------------------------------
:- dynamic(exog_occurs/1).
exog_occurs([]).

%% depth_exhausted/0 is a convenience predicate used only inside
%% poss/2, defined in terms of the depth_used/1 fluent and the
%% instance-specific max_depth/1 fact (see instance_*.pl).
depth_exhausted :- depth_used(N), max_depth(Max), N >= Max.

%% ------------------------------------------------------------
%% Successor state axioms, expressed via causes_true/causes_false
%% (the IndiGolog macros that compile down to Reiter's SSAs).
%% ------------------------------------------------------------
causes_true(at(R2),  move(_R1,R2,_L), true).
causes_false(at(R1), move(R1,_R2,_L), true).

causes_true(depth_used(N1), move(_,_,_), N1 is N + 1) :- depth_used(N).

causes_true(has(I),       pick_up(I,_R), true).
causes_false(item_at(I,R), pick_up(I,R), true).

causes_true(has(I3),  combine(_I1,_I2,I3), true).
causes_false(has(I1), combine(I1,_I2,_I3), true).
causes_false(has(I2), combine(_I1,I2,_I3), true).

causes_true(known_code(L), read_clue(L,_R), true).
causes_true(known_code(L), hint_revealed(L), true).   % exogenous shortcut

causes_true(unlocked(L), unlock_with_key(L,_I), true).
causes_true(unlocked(L), unlock_with_code(L), true).

causes_true(blocked(R1,R2), door_jams(R1,R2), true).
causes_true(blocked(R2,R1), door_jams(R1,R2), true).  % doors are symmetric

%% ------------------------------------------------------------
%% Reasoning-task helper predicates (used by reasoning_tasks.pl)
%% ------------------------------------------------------------
%% goal_reached: true once the agent stands in the designated
%% exit room for the loaded instance.
goal_reached :- at(R), exit_room(R).

