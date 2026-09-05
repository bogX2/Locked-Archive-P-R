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
%% Small typing helper: true for any object that is either kind
%% of lock (used to restrict pi/2 choices below).
%% ------------------------------------------------------------
is_lock(L) :- key_lock(L).
is_lock(L) :- code_lock(L).

%% ------------------------------------------------------------
%% any_action: nondeterministically perform exactly ONE primitive
%% world action, restricted by type to keep the search space
%% small. Whether the chosen action is actually legal in the
%% current situation is decided automatically by the interpreter
%% via poss/2 in escape_room_domain.pl -- we only restrict the
%% TYPES of the arguments here.
%%
%% pi/2 nested form, confirmed working against a real, complete,
%% successfully-graded course project (sokoban.pl's move_somewhere/
%% push_something/slip_something use exactly this nested style,
%% e.g. "pi(l1, [..., pi(l2, [...])])").
%% ------------------------------------------------------------
proc(any_action,
  ndet(
    pi(r1, pi(r2, pi(l,
      [ ?(room(r1)), ?(room(r2)), ?(is_lock(l)), move(r1,r2,l) ]
    ))),
  ndet(
    pi(i, pi(r,
      [ ?(item(i)), ?(room(r)), pick_up(i,r) ]
    )),
  ndet(
    pi(i1, pi(i2, pi(i3,
      [ ?(item(i1)), ?(item(i2)), ?(item(i3)), combine(i1,i2,i3) ]
    ))),
  ndet(
    pi(l, pi(r,
      [ ?(is_lock(l)), ?(room(r)), read_clue(l,r) ]
    )),
  ndet(
    pi(l, pi(i,
      [ ?(is_lock(l)), ?(item(i)), unlock_with_key(l,i) ]
    )),
    pi(l,
      [ ?(is_lock(l)), unlock_with_code(l) ]
    )
  ))))
  )
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
%% ------------------------------------------------------------
rel_fluent(world_changed).
causes_true(hint_revealed(_), world_changed, true).
causes_true(door_jams(_,_),   world_changed, true).

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
