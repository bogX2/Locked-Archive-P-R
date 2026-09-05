%% ============================================================
%% Instance: MEDIUM -- 5 rooms, one mandatory combine step.
%% Mirrors pddl/problems/problem_medium.pddl.
%% ============================================================

room(r1). room(r2). room(r3). room(r4). room(r5).
item(key_a). item(item_x). item(item_y). item(key_c).
key_lock(l1). key_lock(l3).
code_lock(l2). code_lock(l4).

exit_room(r5).

connected(r1,r2,l1). connected(r2,r1,l1).
connected(r2,r3,l2). connected(r3,r2,l2).
connected(r3,r4,l3). connected(r4,r3,l3).
connected(r4,r5,l4). connected(r5,r4,l4).

needs_key(l1,key_a).
needs_key(l3,key_c).

clue_at(l2,r1).
clue_at(l4,r4).

combinable(item_x,item_y,key_c).

%% ------------------------------------------------------------
%% Initial situation, s0.
%% ------------------------------------------------------------
initially(at(r1), true).
initially(at(r2), false).
initially(at(r3), false).
initially(at(r4), false).
initially(at(r5), false).

initially(has(key_a), false).
initially(has(item_x), false).
initially(has(item_y), false).
initially(has(key_c), false).

initially(item_at(key_a,r1), true).
initially(item_at(item_x,r2), true).
initially(item_at(item_y,r3), true).

initially(unlocked(l1), false).
initially(unlocked(l2), false).
initially(unlocked(l3), false).
initially(unlocked(l4), false).

initially(known_code(l2), false).
initially(known_code(l4), false).

initially(blocked(_,_), false).

initially(last_room(_), false).
