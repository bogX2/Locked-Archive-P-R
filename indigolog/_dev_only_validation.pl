%% ============================================================
%% Standalone validation harness (NOT part of the deliverable).
%% Performs a depth-bounded DFS directly over holds/poss (the same
%% action theory used by reasoning_tasks.pl) to confirm that a
%% solution plan exists for each instance, and prints it plus its
%% length. This validates the domain + instance files themselves
%% independently of the official IndiGolog interpreter (which is
%% not available in this sandbox).
%%
%% IMPORTANT: candidate actions are enumerated GROUND (all
%% arguments bound from the static room/item/lock declarations)
%% BEFORE eval/2 is called. Querying a fluent with an unbound
%% argument (e.g. eval(has(I),S) with I free) through the
%% causes_true/causes_false-based holds_fluent/2 in
%% reasoning_tasks.pl only returns the instance(s) tied to the
%% MOST RECENT action, because holds_fluent/2's first clause commits
%% (cuts) as soon as causes_true produces ANY unifying instance --
%% it never backtracks into the frame axiom to also enumerate
%% instances persisting from earlier. Ground queries do not trigger
%% this: holds_fluent/2's cut is then just a (correct) true/false
%% commit, not a lossy enumeration. Enumerating actions ground-first
%% sidesteps the issue entirely.
%% ============================================================

candidate_action(move(R1,R2,L))        :- room(R1), room(R2), ( key_lock(L) ; code_lock(L) ).
candidate_action(pick_up(I,R))         :- item(I), room(R).
candidate_action(combine(I1,I2,I3))    :- item(I1), item(I2), item(I3).
candidate_action(read_clue(L,R))       :- ( key_lock(L) ; code_lock(L) ), room(R).
candidate_action(unlock_with_key(L,I)) :- key_lock(L), item(I).
candidate_action(unlock_with_code(L))  :- code_lock(L).

%% goal_reached/0 in escape_room_domain.pl is written for the live
%% (progression-based) IndiGolog runtime, where fluents are plain
%% asserted facts. Here, in the standalone s0/do(A,S) evaluator, we
%% check the equivalent condition situation-explicitly instead.
reached_goal(S) :- exit_room(R), holds(at(R), S).

next_action(S, A) :- candidate_action(A), prim_action(A), \+ functor(A, move, 3), poss(A, C), eval(C, S).
next_action(S, A) :- candidate_action(A), prim_action(A), functor(A, move, 3), poss(A, C), eval(C, S).

%% state_key/2: canonical fingerprint of the relevant fluents in S,
%% used for genuine cycle detection -- a state is only pruned if it
%% EXACTLY repeats an already-visited state on the current path.
state_key(S, state(AtL,HasL,UnlL,KnL)) :-
  findall(R, (room(R), holds(at(R),S)), AtL),
  findall(I, (item(I), holds(has(I),S)), HasL0), sort(HasL0, HasL),
  findall(L, ((key_lock(L);code_lock(L)), holds(unlocked(L),S)), UnlL0), sort(UnlL0, UnlL),
  findall(L, (code_lock(L), holds(known_code(L),S)), KnL0), sort(KnL0, KnL).

dfs(S, _Bound, _Visited, []) :- reached_goal(S), !.
dfs(S, Bound, Visited, [A|As]) :-
  Bound > 0,
  next_action(S, A),
  Bound1 is Bound - 1,
  state_key(do(A,S), Key),
  \+ member(Key, Visited),
  dfs(do(A,S), Bound1, [Key|Visited], As).

find_plan(Plan) :-
  max_depth(Max),
  state_key(s0, K0),
  dfs(s0, Max, [K0], Plan).

run_check(Label) :-
  format("~n=== ~w ===~n", [Label]),
  ( find_plan(Plan)
  -> length(Plan, Len),
     format("Plan FOUND, length ~w:~n  ~w~n", [Len, Plan])
  ;  format("NO PLAN FOUND within max_depth.~n", [])
  ).
