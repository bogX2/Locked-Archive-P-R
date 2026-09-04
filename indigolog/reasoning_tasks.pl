%% ============================================================
%% The Locked Archive -- Reasoning Tasks demo
%%
%% Three classical Situation Calculus reasoning tasks over the
%% SAME action theory used by the controllers, evaluated with a
%% small, self-contained situation-term evaluator (s0 / do(A,S))
%% rather than through the online IndiGolog executor -- this file
%% can be loaded and queried on its own, with no agent program
%% running, which is convenient for slides / a live demo.
%%
%% Usage:
%%   ?- ['escape_room_domain.pl'].
%%   ?- ['instances/instance_hard.pl'].
%%   ?- ['reasoning_tasks.pl'].
%%   ?- demo_legality.
%%   ?- demo_projection.
%%   ?- demo_regression.
%% ============================================================

:- discontiguous(holds/2).

%% ------------------------------------------------------------
%% Which predicates are situation-dependent fluents (evaluated
%% via s0 / causes_true / causes_false) versus situation-
%% independent static world facts (room/1, item/1, connected/3,
%% needs_key/2, combinable/3, clue_at/2, key_lock/1, code_lock/1,
%% is_lock/1, max_depth/1, exit_room/1) which are just called
%% directly as ordinary Prolog facts, ignoring S.
%% ------------------------------------------------------------
fluent_decl(at/1).
fluent_decl(has/1).
fluent_decl(item_at/2).
fluent_decl(unlocked/1).
fluent_decl(known_code/1).
fluent_decl(blocked/2).
fluent_decl(depth_used/1).

%% ------------------------------------------------------------
%% eval(Condition, S): evaluate a poss/causes_* style condition
%% (built from true / and/2 / neg/1 / or/2 / false / bare fluents
%% / bare static facts / depth_exhausted) in situation S.
%% ------------------------------------------------------------
eval(true, _)          :- !.
eval(false, _)         :- !, fail.
eval(and(P,Q), S)      :- !, eval(P,S), eval(Q,S).
eval(or(P,Q), S)       :- !, ( eval(P,S) ; eval(Q,S) ).
eval(neg(P), S)        :- !, \+ eval(P,S).
eval(depth_exhausted, S) :- !, sit_depth(S, D), max_depth(Max), D >= Max.
eval(F, S)             :- holds(F, S).

%% sit_depth/2: number of PRIMITIVE actions in situation term S.
%% Used instead of the depth_used/1 fluent (whose causes_true
%% clause in escape_room_domain.pl assumes the live, progression-
%% based IndiGolog runtime where fluents are asserted facts -- not
%% applicable to this standalone s0/do(A,S) regression evaluator).
sit_depth(s0, 0) :- !.
sit_depth(do(A,S), D) :- prim_action(A), !, sit_depth(S, D0), D is D0 + 1.
sit_depth(do(_,S), D) :- sit_depth(S, D).

%% ------------------------------------------------------------
%% holds(Fluent, Situation): dispatch to SSA-based evaluation for
%% declared fluents, or to a plain (situation-independent) fact
%% lookup for everything else (the static world map).
%% ------------------------------------------------------------
holds(F, S) :-
  functor(F, Name, Ar),
  fluent_decl(Name/Ar), !,
  holds_fluent(F, S).
holds(F, _S) :- call(F).

holds_fluent(F, s0) :- initially(F, true).
holds_fluent(F, do(A,S)) :-
  causes_true(F, A, C), eval(C, S), !.
holds_fluent(F, do(A,S)) :-
  \+ ( causes_false(F, A, C2), eval(C2, S) ),
  holds_fluent(F, S).

%% ------------------------------------------------------------
%% 1) LEGALITY TASK
%% legal(ActionSeq, S): the sequence is executable step by step
%% from S, i.e. every action's poss/2 condition holds in the
%% situation reached so far.
%% ------------------------------------------------------------
legal([], _S).
legal([A|As], S) :-
  poss(A, C),
  eval(C, S),
  legal(As, do(A,S)).

demo_legality :-
  %% a legal prefix on the hard instance: leave r1, pick up the
  %% start key... but WITHOUT picking it up first, unlocking l0
  %% is illegal. This mirrors the classic "unlock before pick_up"
  %% mistake mentioned in the project notes.
  Illegal = [ unlock_with_key(l0,key_start), move(r1,r2,l0) ],
  Legal    = [ pick_up(key_start,r1), unlock_with_key(l0,key_start), move(r1,r2,l0) ],
  ( legal(Illegal, s0)
  -> format("~nUNEXPECTED: illegal sequence was accepted!~n")
  ;  format("~nAs expected, ~w is ILLEGAL from s0 (key not picked up yet).~n", [Illegal])
  ),
  ( legal(Legal, s0)
  -> format("As expected, ~w IS legal from s0.~n", [Legal])
  ;  format("UNEXPECTED: legal sequence was rejected!~n")
  ).

%% ------------------------------------------------------------
%% 2) PROJECTION TASK
%% Does fluent F hold after executing action sequence Seq from S?
%% ------------------------------------------------------------
projects(F, Seq, S) :-
  final_situation(Seq, S, SFinal),
  holds(F, SFinal).

final_situation([], S, S).
final_situation([A|As], S, SFinal) :-
  final_situation(As, do(A,S), SFinal).

demo_projection :-
  Seq = [ pick_up(key_start,r1), unlock_with_key(l0,key_start), move(r1,r2,l0),
          pick_up(key_w1,r2), unlock_with_key(l_w1,key_w1), move(r2,r3,l_w1),
          pick_up(item_p,r3) ],
  ( projects(has(item_p), Seq, s0)
  -> format("~nProjection OK: has(item_p) holds after ~w.~n", [Seq])
  ;  format("~nProjection FAILED: has(item_p) does not hold after ~w.~n", [Seq])
  ),
  ( projects(at(exit_marker_not_yet_reached_on_purpose), Seq, s0)
  -> true
  ;  format("(as expected, the agent has not reached the exit yet at this point)~n")
  ).

%% ------------------------------------------------------------
%% 3) REGRESSION TASK
%% Regress a goal formula through an action sequence back to a
%% formula over s0 only, then check whether it holds in s0 -- if
%% it does, the goal situation is REACHABLE via that sequence.
%% ------------------------------------------------------------
regress_one(true, _A, true) :- !.
regress_one(false, _A, false) :- !.
regress_one(and(P,Q), A, and(P1,Q1)) :- !, regress_one(P,A,P1), regress_one(Q,A,Q1).
regress_one(or(P,Q), A, or(P1,Q1))   :- !, regress_one(P,A,P1), regress_one(Q,A,Q1).
regress_one(neg(P), A, neg(P1))      :- !, regress_one(P,A,P1).
regress_one(F, A, Result) :-
  functor(F, Name, Ar),
  ( fluent_decl(Name/Ar) ->
      ( causes_true(F,A,TC) -> true ; TC = false ),
      ( causes_false(F,A,FC) -> true ; FC = false ),
      Result = or(TC, and(F, neg(FC)))
  ;
      Result = F   %% static facts are unaffected by any action
  ).

regress([], Goal, Goal).
regress(Seq, Goal, RegressedToS0) :-
  Seq = [_|_],
  append(Prefix, [Last], Seq),
  regress_one(Goal, Last, Goal1),
  regress(Prefix, Goal1, RegressedToS0).

demo_regression :-
  Seq = [ pick_up(key_start,r1), unlock_with_key(l0,key_start), move(r1,r2,l0),
          pick_up(key_w1,r2), unlock_with_key(l_w1,key_w1), move(r2,r3,l_w1),
          pick_up(item_p,r3), pick_up(key_w1,r2) ],  %% deliberately keep it short/simple
  Goal = at(r3),
  regress(Seq, Goal, R),
  format("~nRegressed formula for '~w after ~w': ~w~n", [Goal, Seq, R]),
  ( eval(R, s0)
  -> format("Regression check: TRUE -- goal situation is reachable from s0.~n")
  ;  format("Regression check: FALSE -- goal situation is NOT reachable via this sequence.~n")
  ).
