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
%% IMPORTANT (lesson learned the hard way): pi/2 must be NESTED,
%% e.g. pi(X, pi(Y, Body)) -- passing a variable list such as
%% pi([X,Y], Body) is silently accepted by SWI-Prolog's parser
%% but is NOT how the IndiGolog interpreter's Trans/Final clauses
%% for pi/2 are defined, and it will not bind the variables as
%% expected. Every multi-argument action below is therefore
%% built from nested pi/2 calls.
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
%% Termination is guaranteed by the depth_used/max_depth bound
%% baked into poss(move(...)) in escape_room_domain.pl -- without
%% it, star(any_action) can cycle forever alternating two
%% "move / move back" actions and the offline search below never
%% returns (this was the very first bug found while testing on
%% the interpreter).
%% ------------------------------------------------------------
proc(escape_task,
  [ star(any_action), ?(goal_reached) ]
).

%% ------------------------------------------------------------
%% Simple Controller: one depth-bounded offline search, executed
%% online once a solution is found.
%% ------------------------------------------------------------
proc(control_simple,
  search(escape_task)
).
proc(control(simple), control_simple).   % course-style alias (see main_*.pl)

%% ------------------------------------------------------------
%% Reactive Controller: prioritized_interrupts re-evaluates the
%% situation before every single action.
%%   priority 1: stop as soon as the goal already holds.
%%   priority 2: otherwise, offline-search for just ONE more
%%               action that keeps a solution reachable, execute
%%               it, then recurse -- so the very next decision is
%%               made again from the fresh (possibly exogenously
%%               updated) situation.
%% ------------------------------------------------------------
proc(control_reactive,
  prioritized_interrupts(
    [ interrupt(goal_reached, []),
      interrupt(true, [ search([any_action, ?(escape_still_possible)]),
                         control_reactive ])
    ]
  )
).
proc(control(reactive), control_reactive).   % course-style alias (see main_*.pl)

%% escape_still_possible: cheap sanity check used as the search
%% target for a single reactive step -- true if, from here, the
%% remaining (bounded) task can still in principle be completed.
escape_still_possible :- goal_reached.
escape_still_possible :- \+ goal_reached, \+ depth_exhausted.
