%% ============================================================
%% The Locked Archive -- Escape Room Solver
%% Situation Calculus action theory (Reiter-style), written for
%% the official IndiGolog interpreter's STANDALONE "plain"
%% implementation (interpreters/indigolog_plain.pl).
%%
%% IMPORTANT -- confirmed directly from indigolog_plain.pl's own
%% source: this interpreter bundles its OWN embedded temporal
%% projector and does NOT load eval/eval_bat.pl. Its has_val/
%% sets_val mechanism ONLY understands:
%%   - prim_fluent/1        (NOT rel_fluent/1 + fun_fluent/1)
%%   - causes_val(Action, Fluent, Value, Cond)
%%                           (NOT causes_true/3 + causes_false/3)
%%   - initially(Fluent, Value) for the base case (history = [])
%% causes_true/causes_false and rel_fluent/fun_fluent are an
%% eval_bat.pl-specific convention (used by taxi.pl / sokoban.pl,
%% both of which load eval_bat.pl separately via
%% "dir(eval_bat, F), consult(F)." in their main.pl) -- since
%% indigolog_plain.pl never loads that bridge, causes_true/false
%% clauses written against it are silently NEVER APPLIED: every
%% fluent update is invisible to the interpreter, which is why
%% earlier attempts kept looping (e.g. item_at/2 never actually
%% became false after pick_up, so it stayed legal forever).
%%
%% Load order expected by main_*.pl:
%%   1. config.pl, then dir(indigolog_plain, F), consult(F).
%%   2. this file (escape_room_domain.pl)
%%   3. controllers.pl
%%   4. one instance_*.pl file (initial situation + map layout)
%%   5. call: initialize. (NOT initialize(evaluator) -- confirmed
%%      arity 0 for indigolog_plain), then run a main procedure.
%% ============================================================

:- discontiguous(prim_action/1).
:- discontiguous(poss/2).
:- discontiguous(causes_val/4).
%% multifile: prim_fluent/1 and causes_val/4 get MORE clauses added
%% from controllers.pl (the world_changed fluent, used only by the
%% Reactive Controller).
:- multifile(prim_fluent/1).
:- multifile(causes_val/4).

%% ------------------------------------------------------------
%% Mandatory IndiGolog boilerplate. cache/1 must exist (even if
%% always false) or the evaluator throws existence errors.
%% ------------------------------------------------------------
cache(_) :- fail.

%% ------------------------------------------------------------
%% Primitive fluents (all relational/boolean here: true or false).
%% Declared via prim_fluent/1 -- the predicate indigolog_plain.pl's
%% own subf/3 actually checks (confirmed from its source and from
%% elevator_01.pl's "prim_fluent(floor)." / "prim_fluent(light(N))
%% :- fl(N)." -- NOT rel_fluent/1, which is an eval_bat.pl-only
%% convention this interpreter never looks at).
%% ------------------------------------------------------------
prim_fluent(at(_)).            % at(Room)          -- agent's current room
prim_fluent(has(_)).           % has(Item)         -- agent carries Item
prim_fluent(item_at(_,_)).     % item_at(Item,Room)
prim_fluent(unlocked(_)).      % unlocked(Lock)
prim_fluent(known_code(_)).    % known_code(Lock)
prim_fluent(blocked(_,_)).     % blocked(R1,R2)    -- door temporarily jammed
prim_fluent(last_room(_)).     % last_room(Room)   -- room left by the most recent move (anti-cycle)

%% ------------------------------------------------------------
%% Static (world-map) relations -- plain facts, not fluents.
%% Declared per instance file: connected/3, needs_key/2,
%% combinable/3, clue_at/2, key_lock/1, code_lock/1, room/1,
%% item/1, exit_room/1.
%% ------------------------------------------------------------

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
%% exog_occurs/1: MANDATORY interpreter hook. Confirmed against
%% indigolog_plain.pl's own main loop ("once(exog_occurs(Act)),
%% exog_action(Act), !, ...") and the course's lab files:
%%   - Signature is exog_occurs(Action) -- ONE action, NOT a list.
%%   - "Nothing happened" = FAILING (elevator_01.pl: "exog_occurs(_)
%%     :- fail."). Succeeding binds Action to the specific
%%     exogenous action that occurred.
%% Declared dynamic so demo_exog_harness.pl can cleanly REPLACE this
%% fallback (retractall + reassert in the correct clause order).
%% ------------------------------------------------------------
:- dynamic(exog_occurs/1).
exog_occurs(_) :- fail.

%% ------------------------------------------------------------
%% Successor state axioms, expressed as causes_val/4 -- the ONLY
%% form indigolog_plain.pl's sets_val/4 actually understands:
%%   sets_val(Act, F, V, H) :- Act = e(F, V) ;
%%                             (causes_val(Act, F, V, P), holds(P, H)).
%% For a boolean/relational fluent, each old causes_true/causes_false
%% pair becomes two causes_val clauses (Value = true / Value = false).
%% ------------------------------------------------------------
causes_val(move(_R1,R2,_L), at(R2), true,  true).
causes_val(move(R1,_R2,_L), at(R1), false, true).

causes_val(pick_up(I,_R), has(I),        true,  true).
causes_val(pick_up(I,R),  item_at(I,R),  false, true).

causes_val(combine(_I1,_I2,I3), has(I3), true,  true).
causes_val(combine(I1,_I2,_I3), has(I1), false, true).
causes_val(combine(_I1,I2,_I3), has(I2), false, true).

causes_val(read_clue(L,_R),    known_code(L), true, true).
causes_val(hint_revealed(L),   known_code(L), true, true).   % exogenous shortcut

causes_val(unlock_with_key(L,_I), unlocked(L), true, true).
causes_val(unlock_with_code(L),   unlocked(L), true, true).

causes_val(door_jams(R1,R2), blocked(R1,R2), true, true).
causes_val(door_jams(R1,R2), blocked(R2,R1), true, true).  % doors are symmetric

%% ------------------------------------------------------------
%% last_room/1: the room the agent was in just before its most
%% recent move. Used ONLY to block immediately undoing a move --
%% the one simple, unbounded cycle that would otherwise let an
%% offline search over star(any_action) recurse forever. Same
%% anti-cycle technique as sokoban.pl's last_at/1 (adapted to the
%% causes_val/4 convention this interpreter actually uses).
%% ------------------------------------------------------------
causes_val(move(R1,_R2,_L), last_room(R1), true,  true).
causes_val(move(R1,_R2,_L), last_room(X),  false, X \= R1).

%% ------------------------------------------------------------
%% Reasoning-task helper predicates (used by reasoning_tasks.pl)
%% ------------------------------------------------------------
%% goal_reached: true once the agent stands in the designated
%% exit room for the loaded instance. Defined as a proc/2
%% abbreviation (NOT a plain Prolog ":-" rule) so the interpreter
%% evaluates it correctly against whatever (possibly hypothetical)
%% history it is actually reasoning about -- mirrors the course's
%% own elevator_01.pl abbreviations, e.g. "proc(pending_floor(N),
%% light(N) = on)."
%% ------------------------------------------------------------
proc(goal_reached, some(r, and(exit_room(r), at(r)))).
