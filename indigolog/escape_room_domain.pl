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
%% multifile: rel_fluent/1 and causes_true/3 get MORE clauses added
%% from controllers.pl (the world_changed fluent, used only by the
%% Reactive Controller) -- without this, SWI just warns ("Redefined
%% static procedure"), it isn't fatal, but multifile is the correct
%% declaration for predicates legitimately split across files.
:- multifile(rel_fluent/1).
:- multifile(causes_true/3).

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
                         neg(blocked(R1,R2)))))).

poss(pick_up(I,R), and(at(R), item_at(I,R))).

poss(combine(I1,I2,I3), and(has(I1), and(has(I2), combinable(I1,I2,I3)))).

poss(read_clue(L,R), and(at(R), clue_at(L,R))).

poss(unlock_with_key(L,I), and(needs_key(L,I), has(I))).

poss(unlock_with_code(L), known_code(L)).

%% exogenous events are always possible for the environment to fire
poss(hint_revealed(_), true).
poss(door_jams(_,_), true).

%% ------------------------------------------------------------
%% exog_occurs/1: MANDATORY interpreter hook. Confirmed against the
%% course's own lab files (elevator_01.pl / elevator_02.pl):
%%   - Signature is exog_occurs(Action) -- ONE action, NOT a list.
%%   - "Nothing happened" is expressed by FAILING, not by
%%     succeeding with some empty/trivial term (elevator_01.pl,
%%     which has no exogenous events at all, uses exactly
%%     "exog_occurs(_) :- fail."). Succeeding binds Action to the
%%     specific exogenous action that just occurred (elevator_02.pl
%%     delegates to the interactive ask_exog_occurs/1 for that).
%% Declared dynamic so demo_exog_harness.pl can cleanly REPLACE this
%% fallback (retractall + reassert in the correct clause order) to
%% script hint_revealed/door_jams for the live presentation demo,
%% instead of just adding a clause after it (which would never be
%% reached, since this catch-all "always fail" clause matches --
%% well, fails -- last regardless, but a scripted clause added
%% AFTER it would never even be tried once this one already failed
%% the whole predicate for that call; it must come BEFORE).
%% ------------------------------------------------------------
:- dynamic(exog_occurs/1).
exog_occurs(_) :- fail.

%% ------------------------------------------------------------
%% NOTE on depth bounding: an earlier version of this file tried to
%% bound search depth with a "depth_used/1" counting fluent and a
%% derived depth_exhausted/0 check inside poss(move,...). That
%% approach relied on a causes_true clause body directly CALLING
%% depth_used(N) as a plain Prolog goal to read "the current count"
%% -- which is exactly the unbound-argument / regression-vs-
%% progression pitfall documented in RESULTS.md ("a real bug found
%% and fixed along the way"): in a regression-based projector like
%% eval_bat.pl, that bare call only ever sees the ORIGINAL s0 fact
%% (depth_used(0)), never the true count for a longer history, so
%% the bound silently never triggers. Depth bounding is therefore
%% done structurally in the CONTROL PROGRAM instead (see
%% bounded_task/1 in controllers.pl), which sidesteps the issue
%% entirely by counting down through ordinary program recursion
%% rather than through a fluent.
%% ------------------------------------------------------------

%% ------------------------------------------------------------
%% Successor state axioms, expressed via causes_true/causes_false
%% (the IndiGolog macros that compile down to Reiter's SSAs).
%% ------------------------------------------------------------
causes_true(at(R2),  move(_R1,R2,_L), true).
causes_false(at(R1), move(R1,_R2,_L), true).


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
%% last_room/1: the room the agent was in just before its most
%% recent move. Used ONLY to block immediately undoing a move
%% (moving straight back to where you just came from) -- the one
%% simple, unbounded cycle that would otherwise let an offline
%% search over star(any_action) recurse forever without ever
%% backtracking to try a different, goal-reaching branch. This is
%% the exact same anti-cycle technique used (and confirmed working)
%% in the course's own sokoban.pl reference project:
%%   rel_fluent(last_at(L)) :- loc(L).
%%   causes_true(move(L1,_L2), last_at(L1), true).
%%   causes_false(move(L1,_L2), last_at(X), X \= L1).
%% ------------------------------------------------------------
:- dynamic(last_room/1).
rel_fluent(last_room(_)).
causes_true(last_room(R1),  move(R1,_R2,_L), true).
causes_false(last_room(X),  move(R1,_R2,_L), X \= R1).

%% ------------------------------------------------------------
%% Reasoning-task helper predicates (used by reasoning_tasks.pl)
%% ------------------------------------------------------------
%% goal_reached: true once the agent stands in the designated
%% exit room for the loaded instance. Defined as a proc/2
%% abbreviation (NOT a plain Prolog ":-" rule) so the interpreter
%% evaluates it correctly against whatever situation it is actually
%% reasoning about (in particular, the HYPOTHETICAL situations
%% explored during an offline search/1, not just the live current
%% one) -- this mirrors exactly how the course's own elevator_01.pl
%% defines its abbreviations, e.g. "proc(pending_floor(N), light(N)
%% = on)." rather than a bare ":-" clause. A plain ":-" rule calling
%% a fluent directly bypasses the interpreter's situation-threading
%% and only ever reflects the real, currently-executing situation --
%% which made search(escape_task) unable to ever recognize the goal
%% as reached during its own internal hypothetical exploration.
%% ------------------------------------------------------------
proc(goal_reached, some(r, and(exit_room(r), at(r)))).

