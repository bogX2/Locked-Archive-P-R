%% ============================================================
%% Instance: EASY -- 3 rooms, 1 key lock, 1 code lock.
%% Mirrors pddl/problems/problem_easy.pddl.
%% ============================================================

room(r1). room(r2). room(r3).
item(key1).
key_lock(l1).
code_lock(l2).

exit_room(r3).
max_depth(10).

connected(r1,r2,l1). connected(r2,r1,l1).
connected(r2,r3,l2). connected(r3,r2,l2).

needs_key(l1,key1).
clue_at(l2,r2).
combinable(_,_,_) :- fail.   % no combine puzzle in the easy instance

%% ------------------------------------------------------------
%% Initial situation, s0.
%%
%% TWO representations are kept in sync on purpose:
%%
%% 1) initially(F, true/false) facts -- consumed by the standalone
%%    validator (reasoning_tasks.pl / _dev_only_validation.pl), used
%%    to sanity-check the domain in this sandbox without the real
%%    interpreter.
%% 2) Plain fact declarations for every fluent TRUE in s0 -- this is
%%    what the REAL course interpreter's projector (eval_bat.pl)
%%    actually reads: holds(F, []) calls F directly as a goal, so
%%    every TRUE-in-s0 fluent must exist as a literal fact with that
%%    exact name/arity. Fluents that are false in s0 are simply
%%    omitted (closed-world assumption) -- do NOT add "false" facts
%%    here, only "true" ones.
%% ------------------------------------------------------------
initially(at(r1), true).
initially(at(r2), false).
initially(at(r3), false).

initially(has(key1), false).
initially(item_at(key1,r1), true).

initially(unlocked(l1), false).
initially(unlocked(l2), false).

initially(known_code(l2), false).

initially(blocked(_,_), false).

initially(depth_used(0), true).

%% --- plain facts for the real interpreter (s0 = []) ---
at(r1).
item_at(key1,r1).
depth_used(0).
