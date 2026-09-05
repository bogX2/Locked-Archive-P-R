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
%% via ndet/2 over the NAMES -- exactly the structure used (and
%% confirmed working) in sokoban.pl's "do_something":
%%   proc(do_something, ndet(move_somewhere, ndet(slip_something, push_something))).
%%
%% IMPORTANT (further correction): the earlier version of this file
%% added explicit type-checking tests like ?(room(r1)), ?(item(i)),
%% ?(is_lock(l)) before each action. sokoban.pl's own move_somewhere/
%% push_something/slip_something never do this -- they rely
%% entirely on FLUENTS (self_at, adjacent, at/2, is_slippery) to
%% naturally constrain pi's existential choices, and let poss/2
%% (triggered automatically when the interpreter tries to execute
%% the primitive action itself) do all remaining legality checking.
%% Bare static-fact "type" predicates used directly as a ?/1
%% argument are exactly the pattern that broke earlier (is_lock,
%% goal_reached) -- removing them entirely, rather than continuing
%% to individually wrap each one in proc/2, is both simpler and
%% matches the proven reference structure more closely. The only
%% tests kept below are genuine FLUENT conditions (has/1,
%% unlocked/1, known_code/1, last_room/1) needed to prevent
%% pointless repeats/cycles -- everything else is left for poss/2
%% (in escape_room_domain.pl) to check when the action is attempted.
%% ------------------------------------------------------------
proc(do_move,
  pi(r1, pi(r2, pi(l,
    [ ?(neg(last_room(r2))), move(r1,r2,l) ]
  )))
).

proc(do_pick_up,
  pi(i, pi(r,
    [ ?(neg(has(i))), pick_up(i,r) ]
  ))
).

proc(do_combine,
  pi(i1, pi(i2, pi(i3,
    combine(i1,i2,i3)
  )))
).

proc(do_read_clue,
  pi(l, pi(r,
    [ ?(neg(known_code(l))), read_clue(l,r) ]
  ))
).

proc(do_unlock_key,
  pi(l, pi(i,
    [ ?(neg(unlocked(l))), unlock_with_key(l,i) ]
  ))
).

proc(do_unlock_code,
  pi(l,
    [ ?(neg(unlocked(l))), unlock_with_code(l) ]
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
%% world_changed: set true by either exogenous event, used only by
%% the Reactive Controller below to know when to re-search (mirrors
%% sokoban.pl's "world_updated" / taxi.pl's "has_changed" fluent).
%% Uses causes_val/4 (NOT causes_true/3), matching the convention
%% indigolog_plain.pl's own projector actually understands.
%% ------------------------------------------------------------
prim_fluent(world_changed).
causes_val(hint_revealed(_), world_changed, true, true).
causes_val(door_jams(_,_),   world_changed, true, true).

%% ------------------------------------------------------------
%% Reactive Controller: re-searches for a full plan whenever an
%% exogenous event has changed the world, exactly the pattern
%% confirmed working in sokoban.pl's control(reactive):
%%   prioritized_interrupts([
%%     interrupt(Cond, [unset(Flag), gexec(neg(Flag), search(Task))])
%%   ])
%% gexec(Cond, Program) keeps executing Program as long as Cond
%% holds, aborting and letting the interrupt re-fire the moment it
%% doesn't (i.e. the moment world_changed becomes true again).
%% ------------------------------------------------------------
proc(control_reactive, [
  prioritized_interrupts([
    interrupt(neg(goal_reached), [
      unset(world_changed),
      gexec(neg(world_changed), search(escape_task))
    ])
  ])
]).
proc(control(reactive), control_reactive).   % course-style alias (see main_*.pl)
