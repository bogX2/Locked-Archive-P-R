%% ============================================================
%% The Locked Archive -- Reasoning Tasks (Legality, Projection,
%% Regression), using the REAL indigolog_plain.pl interpreter's
%% own confirmed predicates -- indigolog/1, holds/2, search/1 --
%% not a hand-rolled standalone evaluator.
%%
%% Load AFTER config.pl + main_hard.pl (or any main_*.pl) have
%% already loaded the interpreter, domain, controllers and an
%% instance. Usage:
%%   ?- ['indigolog/reasoning_tasks.pl'].
%%   ?- initialize.            % start from a clean s0 each time
%%   ?- demo_legality.
%%   ?- initialize.
%%   ?- demo_projection.
%%   ?- initialize.
%%   ?- demo_regression.
%%
%% IMPORTANT: indigolog/1 and search/1 both EXECUTE for real against
%% the live session state -- re-run "initialize." before each demo
%% below to reset to a clean s0, or the fluents will reflect
%% wherever the previous task left the agent.
%% ============================================================

%% ------------------------------------------------------------
%% 1) LEGALITY TASK
%% indigolog/1 takes the action sequence in NATURAL order (first
%% action executed first) and actually EXECUTES it for real against
%% the live session -- it fails (Prolog false) if any action in the
%% sequence is not legal at the point it is attempted.
%% ------------------------------------------------------------
demo_legality :-
  format("~n=== Legality Task (hard instance) ===~n"),
  %% Illegal: tries to unlock l0 before ever picking up key_start.
  Illegal = [unlock_with_key(l0,key_start), move(r1,r2,l0)],
  ( indigolog(Illegal)
  -> format("UNEXPECTED: illegal sequence was accepted!~n")
  ;  format("As expected, ~w is ILLEGAL from s0 (key not picked up yet).~n", [Illegal])
  ),
  %% Re-initialize: the failed attempt above may have partially
  %% executed legal prefix actions before failing on the illegal one.
  initialize,
  %% Legal: full minimal west-branch plan.
  Legal = [pick_up(key_start,r1), unlock_with_key(l0,key_start), move(r1,r2,l0),
           pick_up(key_w1,r2), unlock_with_key(l_w1,key_w1), move(r2,r3,l_w1),
           pick_up(item_p,r3), read_clue(l_w2,r3), unlock_with_code(l_w2), move(r3,r4,l_w2),
           pick_up(item_q,r4), combine(item_p,item_q,key_w3), unlock_with_key(l_w3,key_w3), move(r4,r5,l_w3),
           read_clue(l_w4,r5), unlock_with_code(l_w4), move(r5,r8,l_w4)],
  ( indigolog(Legal)
  -> format("As expected, the full 17-action west-branch plan IS legal from s0.~n")
  ;  format("UNEXPECTED: legal sequence was rejected!~n")
  ).

%% ------------------------------------------------------------
%% 2) PROJECTION TASK
%% holds/2 takes the action sequence in REVERSED order (most
%% recently executed action FIRST -- mirrors do(a,s) nesting).
%% This is a PURE QUERY -- it does NOT execute anything or change
%% the live session state, unlike indigolog/1 above.
%% ------------------------------------------------------------
demo_projection :-
  format("~n=== Projection Task (hard instance) ===~n"),
  %% Forward-order plan for readability; Reversed is what holds/2
  %% actually needs (built automatically here with reverse/2).
  Forward = [pick_up(key_start,r1), unlock_with_key(l0,key_start), move(r1,r2,l0),
             pick_up(key_w1,r2), unlock_with_key(l_w1,key_w1), move(r2,r3,l_w1),
             pick_up(item_p,r3)],
  reverse(Forward, Reversed),
  ( holds(has(item_p), Reversed)
  -> format("Projection OK: has(item_p) holds after ~w.~n", [Forward])
  ;  format("Projection FAILED: has(item_p) does not hold after ~w.~n", [Forward])
  ),
  ( holds(at(r8), Reversed)
  -> format("UNEXPECTED: at(r8) holds already?!~n")
  ;  format("As expected, the agent has NOT reached the exit yet at this point.~n")
  ).

%% ------------------------------------------------------------
%% 3) REGRESSION TASK
%% Is a goal condition reachable from the CURRENT situation?
%% Uses search/1 + while/2 (NOT [star(any_action), ?(COND)] -- that
%% pattern lets the search wander PAST an already-reached condition
%% before checking it, confirmed while debugging the live demo;
%% while(neg(COND), any_action) checks COND before every step, so it
%% cannot overshoot). This DOES execute the found plan for real if
%% one exists -- call "initialize." first for a check from a clean
%% s0, exactly mirroring the classical situation-calculus question
%% "is this goal situation reachable from the initial situation".
%% ------------------------------------------------------------
demo_regression :-
  format("~n=== Regression Task (hard instance) ===~n"),
  Goal = some(r, and(exit_room(r), at(r))),   % i.e. goal_reached itself
  ( indigolog(search(while(neg(Goal), any_action)))
  -> format("Goal situation ~w IS reachable from the initial situation.~n", [Goal])
  ;  format("Goal situation ~w is NOT reachable from the initial situation.~n", [Goal])
  ).

%% ------------------------------------------------------------
%% Interactive versions (course-style, read the sequence/condition
%% from the console instead of a hard-coded example) -- mirrors the
%% taxi_planning reference project's legality_task/projection_task/
%% regression_task predicates.
%% ------------------------------------------------------------
legality_task :-
  format("Write the sequence of actions '[a1(), ..., an()].' (natural order):~n"),
  read(SEQ), nl,
  ( indigolog(SEQ)
  -> format("Sequence ~w IS legal (and has now been executed).~n", [SEQ])
  ;  format("Sequence ~w is NOT legal.~n", [SEQ])
  ).

projection_task :-
  format("Write the condition 'and(f1(), neg(f2())).':~n", []),
  read(COND),
  format("Write the action sequence in REVERSED order '[an(), ..., a1()].':~n", []),
  read(SEQ),
  ( holds(COND, SEQ)
  -> format("Condition ~w HOLDS after the sequence.~n", [COND])
  ;  format("Condition ~w DOES NOT HOLD after the sequence.~n", [COND])
  ).

regression_task :-
  format("Write the goal condition 'and(f1(), neg(f2())).':~n", []),
  read(COND),
  ( indigolog(search(while(neg(COND), any_action)))
  -> format("Goal condition ~w IS reachable from the current situation.~n", [COND])
  ;  format("Goal condition ~w is NOT reachable from the current situation.~n", [COND])
  ).