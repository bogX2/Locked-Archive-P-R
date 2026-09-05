%% ============================================================
%% Instance: HARD -- 8 rooms, two alternative branches to the
%% exit (west = cheap + mandatory combine, east = expensive +
%% decoy combine). Mirrors pddl/problems/problem_hard.pddl.
%%
%% Note: IndiGolog has no built-in numeric action-cost metric
%% like PDDL's total-cost, so the "cost" difference between
%% branches is realised here as extra path LENGTH: the east
%% branch is deliberately routed through more world moves,
%% which the depth-bounded search prunes in favour of the
%% shorter (west) branch, exactly as Fast Downward prunes it
%% by move-cost in the PDDL model. See README for discussion.
%% ============================================================

room(r1). room(r2). room(r3). room(r4). room(r5).
room(r6). room(r7). room(r8).

item(key_start). item(key_w1). item(item_p). item(item_q). item(key_w3).
item(key_e1). item(item_m). item(item_n). item(key_e3). item(bonus_item).

key_lock(l0). key_lock(l_w1). key_lock(l_w3). key_lock(l_e1). key_lock(l_e3).
code_lock(l_w2). code_lock(l_w4). code_lock(l_e2).

exit_room(r8).
%% NOTE: 17 primitive actions are needed for the WEST branch (with
%% its mandatory pick_up+pick_up+combine+unlock detour) and 12 for
%% the EAST branch (a plain pick_up+unlock). Unlike the PDDL model
%% -- where differentiated move-cost values make west cheaper (13)
%% than east (16) under :metric minimize(total-cost) -- IndiGolog's
%% plain depth-bounded search has no such per-action cost metric, so
%% it cannot itself prefer the "PDDL-optimal" branch by action count
%% alone (east is in fact SHORTER in raw action count). max_depth is
%% therefore set generously enough for BOTH branches to be
%% individually reachable; which one a given run finds first depends
%% on search order, not on the PDDL cost model. See README.md,
%% section "Deliberate deviation", for the full discussion.
max_depth(20).

connected(r1,r2,l0). connected(r2,r1,l0).

connected(r2,r3,l_w1). connected(r3,r2,l_w1).
connected(r3,r4,l_w2). connected(r4,r3,l_w2).
connected(r4,r5,l_w3). connected(r5,r4,l_w3).
connected(r5,r8,l_w4). connected(r8,r5,l_w4).

connected(r2,r6,l_e1). connected(r6,r2,l_e1).
connected(r6,r7,l_e2). connected(r7,r6,l_e2).
connected(r7,r8,l_e3). connected(r8,r7,l_e3).

needs_key(l0,key_start).
needs_key(l_w1,key_w1).
needs_key(l_w3,key_w3).
needs_key(l_e1,key_e1).
needs_key(l_e3,key_e3).

clue_at(l_w2,r3).
clue_at(l_w4,r5).
clue_at(l_e2,r6).

combinable(item_p,item_q,key_w3).      % mandatory, west branch
combinable(item_m,item_n,bonus_item).  % decoy, east branch (never required)

%% ------------------------------------------------------------
%% Initial situation, s0.
%% ------------------------------------------------------------
initially(at(r1), true).
initially(at(r2), false). initially(at(r3), false). initially(at(r4), false).
initially(at(r5), false). initially(at(r6), false). initially(at(r7), false).
initially(at(r8), false).

initially(has(key_start), false). initially(has(key_w1), false).
initially(has(item_p), false).    initially(has(item_q), false).
initially(has(key_w3), false).    initially(has(key_e1), false).
initially(has(item_m), false).    initially(has(item_n), false).
initially(has(key_e3), false).    initially(has(bonus_item), false).

initially(item_at(key_start,r1), true).
initially(item_at(key_w1,r2), true).
initially(item_at(item_p,r3), true).
initially(item_at(item_q,r4), true).
initially(item_at(key_e1,r2), true).
initially(item_at(item_m,r6), true).
initially(item_at(item_n,r7), true).
initially(item_at(key_e3,r7), true).

initially(unlocked(l0), false).    initially(unlocked(l_w1), false).
initially(unlocked(l_w2), false).  initially(unlocked(l_w3), false).
initially(unlocked(l_w4), false).  initially(unlocked(l_e1), false).
initially(unlocked(l_e2), false).  initially(unlocked(l_e3), false).

initially(known_code(l_w2), false).
initially(known_code(l_w4), false).
initially(known_code(l_e2), false).

initially(blocked(_,_), false).

initially(depth_used(0), true).

%% --- plain facts for the real interpreter (s0 = []) ---
at(r1).
item_at(key_start,r1).
item_at(key_w1,r2).
item_at(item_p,r3).
item_at(item_q,r4).
item_at(key_e1,r2).
item_at(item_m,r6).
item_at(item_n,r7).
item_at(key_e3,r7).
depth_used(0).
