%% ============================================================
%% The Locked Archive -- Controllers
%%
%% Two controllers over the SAME action theory
%% (escape_room_domain.pl) and the SAME instance file:
%%
%%   control_simple   -- offline: one full plan is searched for
%%                        up front (via the IndiGolog "search"
%%                        combinator) and then executed step by
%%                        step. If an exogenous event invalidates
%%                        a later step of that fixed plan (e.g. a
%%                        door_jams blocks a door the plan relied
%%                        on), the simple controller has no
%%                        fallback and the run fails.
%%
%%   control_reactive -- online: uses prioritized_interrupts to
%%                        re-decide its next single action at
%%                        EVERY cycle, based on the actual current
%%                        situation (which already reflects any
%%                        exogenous events incorporated since the
%%                        last step). This is what lets it skip a
%%                        read_clue after a hint_revealed event, or
%%                        silently reroute around a jammed door.
%% ============================================================

%% ------------------------------------------------------------
%% any_action: nondeterministically perform exactly ONE primitive
%% world action. Broken into separate NAMED sub-procedures combined
%% via ndet/2 over the NAMES -- the structure used in sokoban.pl's
%% "do_something": proc(do_something, ndet(move_somewhere, ...)).
%%
%% Each sub-procedure GROUNDS its variables first via plain static
%% facts (room/1, item/1, key_lock/1, code_lock/1), THEN checks any
%% negative "don't repeat this pointlessly" guard. Order matters:
%% a negative test like ?(neg(has(i))) alone never BINDS i (negation
%% as failure just checks no solution exists, it doesn't produce
%% one) -- an earlier version of this file removed the grounding
%% tests entirely, which left i/r unbound and made every action a
%% no-op. The actual root cause of the original infinite loop was
%% unrelated (causes_true/false vs. causes_val/4, fixed in
%% escape_room_domain.pl) -- these type-grounding tests were never
%% the problem and are back to stay. or/2 is used directly (a
%% native holds/2 connective, confirmed from indigolog_plain.pl's
%% own source) instead of a separate is_lock/1 abstraction.
%% ------------------------------------------------------------
%% ------------------------------------------------------------
%% do_move: the PREFERRED move -- respects last_room (no immediate
%% backtracking). do_move_fallback (see below, near any_action) is
%% the anti-cycle-IGNORING escape hatch, tried only as the very
%% LAST resort after every other action type has been tried too --
%% NOT bundled inside do_move itself. An earlier version nested the
%% fallback directly inside do_move's own ndet, which made it the
%% SECOND candidate any_action would try overall (right after the
%% preferred move) -- since bouncing back is almost always possible
%% once some door is unlocked, this made the agent prefer endless
%% move/move-back cycling over ever trying pick_up/unlock, causing
%% exactly the infinite r1<->r2 loop seen when actually testing the
%% live exogenous-event demo. Keeping it as the LAST option in
%% any_action's ndet chain instead ensures every productive action
%% (pick_up, combine, read_clue, unlock_*) is tried first.
%% ------------------------------------------------------------
proc(do_move,
  pi(r1, pi(r2, pi(l,
    [ ?(room(r1)), ?(room(r2)), ?(or(key_lock(l), code_lock(l))),
      ?(neg(last_room(r2))), move(r1,r2,l) ]
  )))
).

proc(do_pick_up,
  pi(i, pi(r,
    [ ?(item(i)), ?(room(r)), ?(neg(has(i))), pick_up(i,r) ]
  ))
).

proc(do_combine,
  pi(i1, pi(i2, pi(i3,
    [ ?(item(i1)), ?(item(i2)), ?(item(i3)), combine(i1,i2,i3) ]
  )))
).

proc(do_read_clue,
  pi(l, pi(r,
    [ ?(or(key_lock(l), code_lock(l))), ?(room(r)), ?(neg(known_code(l))), read_clue(l,r) ]
  ))
).

proc(do_unlock_key,
  pi(l, pi(i,
    [ ?(key_lock(l)), ?(item(i)), ?(neg(unlocked(l))), unlock_with_key(l,i) ]
  ))
).

proc(do_unlock_code,
  pi(l,
    [ ?(code_lock(l)), ?(neg(unlocked(l))), unlock_with_code(l) ]
  )
).

proc(any_action,
  ndet(do_move,
  ndet(do_pick_up,
  ndet(do_combine,
  ndet(do_read_clue,
  ndet(do_unlock_key,
       do_unlock_code
  )))))
).

%% ------------------------------------------------------------
%% escape_task: repeat any_action UNTIL the exit room is reached.
%%
%% IMPORTANT (final correction): uses while(neg(goal_reached),
%% any_action), NOT [star(any_action), ?(goal_reached)]. The two
%% look equivalent but are NOT: star/1 always prefers "take one more
%% action" over "stop and check the goal" during DFS exploration
%% (trans/4's list-clause tries "advance the head" before "skip to
%% checking the tail"), so search(escape_task) could keep wandering
%% PAST an already-reached goal room (confirmed live: the search
%% explored move(r8,r5,l_w4) -- moving OUT of the already-reached
%% exit room r8 -- instead of stopping there) once do_move_fallback
%% made many more moves available at every step. while(P,E) checks
%% P explicitly BEFORE every iteration and is immediately final the
%% moment P becomes false, so it cannot wander past a goal it has
%% already reached.
%% ------------------------------------------------------------
proc(escape_task,
  while(neg(goal_reached), any_action)
).

%% ------------------------------------------------------------
%% Simple Controller: one offline search, executed online once a
%% solution is found.
%% ------------------------------------------------------------
proc(control_simple,
  search(escape_task)
).
proc(control(simple), control_simple).   % course-style alias (see main_*.pl)

%% ------------------------------------------------------------
%% Reactive Controller: re-decides one action at a time, checking
%% before each whether the goal already holds.
%%
%% IMPORTANT: any_action is wrapped in search/1 here, NOT called
%% bare. Without it, the online step-by-step trans/4 semantics
%% commits to pi's existential choices (e.g. which room r2 to move
%% to) ONE MICRO-STEP AT A TIME across separate indigo/2 iterations
%% -- if a partially-committed choice later turns out invalid (e.g.
%% r2 ends up equal to r1, so move(r1,r1,_) has no matching
%% connected/3 fact), there is no way to backtrack anymore, since
%% the choice was already locked in through an earlier, separate
%% top-level step (confirmed by manually tracing trans/4 step by
%% step during debugging). search(any_action) fixes this by fully
%% resolving ALL of any_action's internal pi/ndet choices (with
%% complete backtracking) before ever committing a single real
%% action -- exactly the same reason control_simple wraps
%% escape_task in search(...).
%%
%% gexec/2 and unset/1 (used in sokoban.pl's and taxi.pl's reactive
%% controllers) are NOT part of interpreters/indigolog_plain.pl --
%% confirmed by reading its actual source, which only defines: conc,
%% pconc, iconc, ndet, if, while, star, pi, ?, proc, interrupt/2,
%% interrupt/3 and prioritized_interrupts. sokoban.pl/taxi.pl load
%% the FULLER indigolog.pl instead (via "dir(indigolog, F)", not
%% "dir(indigolog_plain, F)"), where gexec/set/unset are presumably
%% provided by additional interpreter modules not present in the
%% plain variant.
%% ------------------------------------------------------------
%% ------------------------------------------------------------
%% Reactive Controller: re-plans the FULL remaining task whenever
%% needed, not just one action at a time.
%%
%% IMPORTANT (final correction after live-testing the exogenous-
%% event demo): search(any_action) -- one action at a time, no
%% lookahead -- is too short-sighted for this domain. It cannot
%% tell "going back to r1 leads nowhere new" from "going to r6
%% leads to the goal" -- both are locally legal, so it can (and
%% did, when actually tested) cycle r1<->r2<->r3 forever once the
%% west branch got blocked, since r1 is just as "valid" a next step
%% as r6 with no lookahead to prefer one over the other.
%%
%% search(escape_task) -- the FULL task, exactly mirroring taxi.pl's
%% and sokoban.pl's own reactive controllers (both use
%% "search(FULL_TASK)" inside their interrupt body, not a single
%% action) -- fixes this: it finds a COMPLETE multi-step plan via
%% proper DFS with backtracking, correctly discovering "back out of
%% r3 via the fallback move, THEN go east" as one coherent solution,
%% rather than making that decision short-sightedly one step at a
%% time. Self-healing after an exogenous event comes for free from
%% indigolog_plain.pl's own followpath/2 semantics: if a later
%% cached step's precondition breaks (e.g. door_jams), followpath's
%% "off path; check again" clause automatically redoes
%% search(escape_task) from the CURRENT (updated) situation --
%% functionally the same effect as taxi.pl/sokoban.pl's
%% gexec+unset pattern, without needing those (unavailable in
%% indigolog_plain.pl) constructs at all.
%% ------------------------------------------------------------
proc(control_reactive, prioritized_interrupts([
  interrupt(neg(goal_reached), search(escape_task))
])).
proc(control(reactive), control_reactive).   % course-style alias (see main_*.pl)