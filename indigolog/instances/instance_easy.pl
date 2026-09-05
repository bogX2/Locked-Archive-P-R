%% ============================================================
%% Instance: EASY -- 3 rooms, 1 key lock, 1 code lock.
%% Mirrors pddl/problems/problem_easy.pddl.
%% ============================================================

room(r1). room(r2). room(r3).
item(key1).
key_lock(l1).
code_lock(l2).

exit_room(r3).

connected(r1,r2,l1). connected(r2,r1,l1).
connected(r2,r3,l2). connected(r3,r2,l2).

needs_key(l1,key1).
clue_at(l2,r2).
combinable(_,_,_) :- fail.   % no combine puzzle in the easy instance

%% ------------------------------------------------------------
%% Initial situation, s0. initially(F, V) is read directly by
%% indigolog_plain.pl's has_val/3 base case ("has_val(F, V, []) :-
%% initially(F, V)."), so this is the ONLY representation needed --
%% no separate plain facts. Every prim_fluent/1 declared in
%% escape_room_domain.pl should have exactly one initially/2 clause
%% per relevant ground instance (true ones are listed; false ones
%% for at/1 are listed too since "at" needs exactly one room true
%% and the rest explicitly false, unlike closed-world defaults).
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

initially(last_room(_), false).
