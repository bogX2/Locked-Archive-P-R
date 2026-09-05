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
%% escape_task: repeat any_action until the exit room is reached.
%% Plain star/1 + a goal test, exactly the pattern confirmed
%% working in sokoban.pl's "dumb" controller:
%%   proc(dumb, [star(do_something), ?(neg(some_boxes_not_on_trg))]).
%% An earlier version of this file replaced star/1 with a hand-
%% rolled numeric "bounded_task" out of an unconfirmed worry about
%% infinite loops -- that extra complexity is removed now that a
%% real working reference project shows plain star/1 is fine here
%% (the earlier "false" / no-solution results were most likely
%% caused by the exog_occurs/1 and goal_reached bugs fixed
%% elsewhere in this file and in escape_room_domain.pl, not by an
%% actual infinite loop in star/1 itself).
%% ------------------------------------------------------------
proc(escape_task,
  [ star(any_action), ?(goal_reached) ]
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
%% IMPORTANT: gexec/2 and unset/1 (used in sokoban.pl's and
%% taxi.pl's reactive controllers) are NOT part of
%% interpreters/indigolog_plain.pl -- confirmed by reading its
%% actual source, which only defines: conc, pconc, iconc, ndet, if,
%% while, star, pi, ?, proc, interrupt/2, interrupt/3 and
%% prioritized_interrupts. sokoban.pl/taxi.pl must be loaded against
%% the FULLER indigolog.pl (as their own main.pl does, via
%% "dir(indigolog, F)", not "dir(indigolog_plain, F)"), where gexec/
%% set/unset are presumably provided by additional interpreter
%% modules not present in the plain variant. Since main_*.pl here
%% loads indigolog_plain specifically, the Reactive Controller is
%% built only from confirmed-available constructs: each interrupt
%% cycle takes exactly one action via any_action while the goal
%% isn't reached yet, naturally picking up any state changes from
%% exogenous events (hint_revealed, door_jams) before every single
%% decision -- interrupt(Trigger, Body) is itself just
%% "while(interrupts=running, if(Trigger, Body, ?(neg(true))))",
%% so this loops correctly on its own without any extra machinery.
%% ------------------------------------------------------------
proc(control_reactive, prioritized_interrupts([
  interrupt(neg(goal_reached), any_action)
])).
proc(control(reactive), control_reactive).   % course-style alias (see main_*.pl)
