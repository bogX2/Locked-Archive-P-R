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
