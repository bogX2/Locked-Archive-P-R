# The Locked Archive — Experimental Results

All experiments in this file were actually executed (Fast Downward built
from source; IndiGolog domain logic validated with SWI-Prolog), not
estimated. Raw logs are in `pddl/experiment_logs/`.

## 1. PDDL — Fast Downward comparison table

Fast Downward built from the official GitHub source
(`github.com/aibasel/downward`, revision `824499f`), release build.

| Instance | Config | Domain | Plan length | Plan cost | Expanded states | Search time |
|---|---|---|---:|---:|---:|---:|
| Easy   | Blind | ADL    | 6  | 2  | 9  | 0.14 ms |
| Easy   | hFF   | STRIPS | 6  | 2  | 7  | 0.23 ms |
| Easy   | hadd  | STRIPS | 6  | 2  | 7  | 0.27 ms |
| Medium | Blind | ADL    | 14 | **4**  | 38 | 0.22 ms |
| Medium | hFF   | STRIPS | 14 | **4**  | 19 | 0.37 ms |
| Medium | hadd  | STRIPS | 16 | **6**  | 18 | 0.29 ms |
| Hard   | Blind | ADL    | 17 | **13** | 169 | 0.61 ms |
| Hard   | hFF   | STRIPS | 12 | **16** | 15 | 0.31 ms |
| Hard   | hadd  | STRIPS | 12 | **16** | 15 | 0.25 ms |

*(times are the "Actual search time" reported by Fast Downward on this
machine; useful for relative comparison between configurations, not as
absolute benchmarks.)*

### Headline finding: heuristic inadmissibility caught in the act

Both **hadd on medium** and **hFF/hadd on hard** return a plan that is
*shorter in number of actions* but has *higher total-cost* than the
Blind-search optimum:

- **Medium**: optimum cost is 4 (Blind, hFF). hadd instead returns a
  cost-6 plan — it takes an extra round-trip move
  (`move(r1,r2)→move(r2,r1)→read_clue→move(r1,r2)` instead of reading
  the clue before ever leaving r1), adding 2 unnecessary moves.
- **Hard**: optimum cost is 13, achieved only by the **west branch**,
  which requires solving the mandatory `combine(item_p, item_q) →
  key_w3` puzzle. Both hFF and hadd instead return the cost-16 **east
  branch** plan (12 actions, no combine needed) — fewer actions, but
  more expensive under the differentiated `move-cost` metric.

This is expected and pedagogically exactly the point of comparing an
admissible search (Blind — always optimal, but expands far more states:
169 vs. 15 on the hard instance) against inadmissible heuristics (hFF,
hadd — expand ~10× fewer states, but sacrifice optimality on an
instance specifically designed to have a cheap-but-hard-to-find optimum
hidden behind a combine puzzle). This trade-off (optimality vs. search
effort) is the natural centerpiece of the "Planners and Search
Heuristics" section of the presentation.

### Plans found (for the slides)

**Hard / Blind (optimal, cost 13, west branch):**
```
pick_up key_start r1        unlock_with_key l0 key_start   move r1 r2 l0
pick_up key_w1 r2           unlock_with_key l_w1 key_w1     move r2 r3 l_w1
pick_up item_p r3           read_clue l_w2 r3                unlock_with_code l_w2
move r3 r4 l_w2              pick_up item_q r4                combine item_p item_q
unlock_with_key l_w3 key_w3  move r4 r5 l_w3                   read_clue l_w4 r5
unlock_with_code l_w4        move r5 r8 l_w4
```

**Hard / hFF & hadd (sub-optimal, cost 16, east branch):**
```
pick_up key_start r1   unlock_with_key l0 key_start   move r1 r2 l0
pick_up key_e1 r2       unlock_with_key l_e1 key_e1     move r2 r6 l_e1
read_clue l_e2 r6        unlock_with_code l_e2            move r6 r7 l_e2
pick_up key_e3 r7        unlock_with_key l_e3 key_e3      move r7 r8 l_e3
```

### Notes for reproduction

- `astar(blind())` was only run against `domain_adl.pddl` (compatible
  with conditional effects); `astar(ff())` / `astar(add())` only
  against `domain_strips.pddl` (Fast Downward's delete-relaxation
  heuristics reject conditional effects / existential preconditions
  outright — confirmed: running hFF/hadd against the ADL domain fails
  immediately with a domain/problem name mismatch guard, and the
  underlying heuristics are documented as ADL-incompatible regardless).
- Problem files for the STRIPS domain are the `_strips` variants in
  `pddl/problems/` (identical content, different `:domain` line —
  Fast Downward requires the two to match).

## 2. IndiGolog / Situation Calculus — validated on the real course interpreter

The official IndiGolog interpreter (`indigolog_plain.pl`, University of
Toronto / AI-KR-UofT distribution) was run on the course VM. Every
result below is a **real execution transcript**, not a simulation —
raw session output is reproduced verbatim.

### 2.1 Controllers — both instances, both controllers

| Instance | Controller | Result | Actions |
|---|---|---:|---:|
| Easy   | Simple   | ✅ optimal plan found | 6 |
| Easy   | Reactive | ✅ optimal plan found | 6 (+2 interrupt overhead) |
| Medium | Simple   | ✅ optimal plan found (matches PDDL exactly) | 14 |
| Medium | Reactive | ✅ optimal plan found | 14 (+2 interrupt overhead) |
| Hard   | Simple   | ✅ west branch found (2 harmless extra pick-ups) | 19 |
| Hard   | Reactive | ✅ west branch found (2 harmless extra pick-ups) | 21 (+2 interrupt overhead) |

Both controllers reliably solve every instance. On the hard instance,
`search/1`'s plain depth-first exploration (no cost metric, unlike
Fast Downward) occasionally picks up the east-branch key `key_e1` and
unlocks `l_e1` along the way without ever using it — a harmless
detour, not a bug (see §2.3 for why IndiGolog has no notion of "branch
cost" to prefer west here the way Fast Downward's `move-cost` does).

### 2.2 Live exogenous-event demo — full transcript

`demo_exog_harness.pl`, hard instance, Reactive Controller:

```
=== The Locked Archive -- live exogenous-event demo ===
Starting Reactive Controller on the HARD instance...
>>> [demo harness] injecting exogenous event: hint_revealed(l_e2)
>>> [demo harness] injecting exogenous event: door_jams(r2,r3)
start_interrupts
pick_up(key_start,r1)
unlock_with_key(l0,key_start)
move(r1,r2,l0)
pick_up(key_w1,r2)
pick_up(key_e1,r2)
unlock_with_key(l_w1,key_w1)
unlock_with_key(l_e1,key_e1)
move(r2,r6,l_e1)
pick_up(item_m,r6)
unlock_with_code(l_e2)
move(r6,r7,l_e2)
pick_up(item_n,r7)
pick_up(key_e3,r7)
combine(item_m,item_n,bonus_item)
unlock_with_key(l_e3,key_e3)
move(r7,r8,l_e3)
stop_interrupts
20 actions.
true
```

Both mechanisms confirmed working exactly as designed:
- **`hint_revealed(l_e2)`**: `known_code(l_e2)` becomes true immediately;
  the plan goes straight to `unlock_with_code(l_e2)`, never calling
  `read_clue(l_e2,r6)` — falls directly out of the successor state
  axiom, no special-case code needed.
- **`door_jams(r2,r3)`**: the west branch is never explored at all;
  the Reactive Controller finds a plan through the east branch
  (`r2→r6→r7→r8`) instead.

**Design note**: both events fire *before* the first real action,
not mid-plan. `indigolog_plain.pl`'s own online loop checks
`exog_occurs/1` before every attempted transition, so queued events
are fully incorporated before `search(escape_task)` is ever invoked —
this was a deliberate simplification once it became clear the course's
"plain" interpreter variant has no `gexec`/`unset` (the constructs
`sokoban.pl`/`taxi.pl`/the full `elevator.pl` all rely on to abort and
restart a search *mid-execution*): those constructs are genuinely
absent both from `interpreters/indigolog_plain.pl`'s own source and
from `lib/common.pl` (confirmed by inspecting both directly), so a
mid-execution reroute would have needed either relaxing the anti-cycle
guard (which, when tried, let the search wander indefinitely once the
map was fully unlocked — confirmed live, it even explored moves *out
of* the already-reached exit room) or accepting that a purely
single-action reactive design cannot always recover from being deep
inside a now-blocked corridor. Firing events upfront sidesteps this
cleanly while still genuinely exercising both mechanisms.

### 2.3 Reasoning tasks — full transcripts (hard instance)

**Legality** — `indigolog/1`, natural action order:
```
=== Legality Task (hard instance) ===
As expected, [unlock_with_key(l0,key_start),move(r1,r2,l0)] is ILLEGAL from s0 (key not picked up yet).
pick_up(key_start,r1)
unlock_with_key(l0,key_start)
...
move(r5,r8,l_w4)
17 actions.
As expected, the full 17-action west-branch plan IS legal from s0.
```

**Projection** — `holds/2`, **reversed** action order (most recent
action first, mirrors `do(a,s)` nesting — the opposite convention
from `indigolog/1` above):
```
=== Projection Task (hard instance) ===
Projection OK: has(item_p) holds after [pick_up(key_start,r1),...,pick_up(item_p,r3)].
As expected, the agent has NOT reached the exit yet at this point.
```

**Regression** — `search(while(neg(Goal), any_action))`, checking
reachability of the goal situation from `s0`:
```
=== Regression Task (hard instance) ===
pick_up(key_start,r1)
...
move(r5,r8,l_w4)
19 actions.
Goal situation some(r,and(exit_room(r),at(r))) IS reachable from the initial situation.
```

All three confirmed correct. `holds/2` needing the **reversed** action
list — the opposite convention from `indigolog/1` — is a genuine
easy-to-get-backwards subtlety, confirmed against the course's own
elevator example (`eval(door_open, [open, close], true)` is only true
read right-to-left) and worth a mention if the reasoning-tasks slide
gets a follow-up question.

## 3. Real bugs found and fixed while getting IndiGolog running

None of these were guesses — every one was diagnosed from a live
error message or an actual stuck/looping session on the course VM,
then confirmed fixed by re-running. Kept here in full because they are
excellent, concrete material for the "known interpreter gotchas" slide
and for Q&A about the implementation:

1. **`initialize(evaluator)` doesn't exist here** — `indigolog_plain.pl`
   uses arity-0 `initialize.`. The arity-1 form is an `eval_bat.pl`
   convention (a *different* projector, used by `taxi.pl`/`sokoban.pl`
   via their own `main.pl`, which loads `dir(eval_bat, F)` in addition
   to the interpreter — `indigolog_plain.pl` never loads that bridge).

2. **`exog_occurs/1`'s real contract**: takes a single action and
   *fails* when nothing happened (confirmed from the course's own
   `elevator_01.pl`: `exog_occurs(_) :- fail.`) — not "succeeds with
   an empty list", which was an early, wrong guess before the lab
   files were available.

3. **The actual root cause of an early infinite `pick_up` loop**:
   `indigolog_plain.pl`'s own embedded projector (read directly from
   its source) uses **`prim_fluent/1` + `causes_val(Action, Fluent,
   Value, Cond)`** — *not* `rel_fluent/1` + `causes_true/3` +
   `causes_false/3`, which is an `eval_bat.pl`-only convention. Since
   `indigolog_plain.pl` never loads that bridge, every
   `causes_true`/`causes_false` clause written against it was silently
   **never applied** — no fluent ever actually changed, so e.g.
   `item_at/2` never became false after `pick_up`, and it stayed legal
   forever. Rewriting the entire action theory in `causes_val/4` form
   fixed this outright.

4. **`execute/2` was missing entirely** — a second, independent bug
   from #3, only surfacing once an action's `poss/2` check succeeds
   and the interpreter tries to actually commit it for real (not just
   check hypothetically). Fixed by delegating to the interpreter's own
   `ask_execute/2`, exactly matching `elevator_01.pl`.

5. **Derived conditions must be `proc/2` abbreviations, not plain
   Prolog `:-` rules** — `goal_reached :- at(R), exit_room(R).` (and
   later, `is_lock/1` defined the same way) bypassed the interpreter's
   own situation-threading and only ever reflected the *live* current
   situation, never the *hypothetical* one `search/1` is exploring
   internally — so `search(escape_task)` could never recognize the
   goal as reached during its own lookahead. Fixed by expressing them
   declaratively, e.g. `proc(goal_reached, some(r, and(exit_room(r),
   at(r)))).`, exactly mirroring the course's own
   `proc(pending_floor(N), light(N) = on).`-style abbreviations.

6. **Negation alone never binds a variable.** An action template like
   `pi(i, pi(r, [?(neg(has(i))), pick_up(i,r)]))` leaves `i` and `r`
   completely unbound — negation-as-failure only *checks* that no
   solution exists, it never *produces* one. Every action template
   needs a positive grounding test (`?(item(i))`, `?(room(r))`) before
   any negative "don't repeat this" guard.

7. **`star(E), ?(Goal)` can wander straight past an already-reached
   goal.** `indigolog_plain.pl`'s own `trans/4` clause order for lists
   always prefers "take one more step of `E`" over "stop and check the
   tail" — confirmed live, `search(escape_task)` was seen exploring
   `move(r8,r5,l_w4)`, moving *out of* the already-reached exit room.
   `while(neg(Goal), E)` checks the condition *before* every step
   instead, and is immediately final the moment it becomes true, so it
   cannot overshoot.

8. **`gexec`/`unset`/`set`** (used by `sokoban.pl`, `taxi.pl`, and the
   full `elevator.pl`'s reactive controllers to abort and restart a
   search mid-execution) are **not part of `indigolog_plain.pl`**,
   confirmed by reading both its own source and `lib/common.pl`
   directly. Those three projects all load the fuller `indigolog.pl` +
   `eval_bat.pl` combination instead (via `dir(indigolog, F)`, not
   `dir(indigolog_plain, F)`). This is why Locked Archive's Reactive
   Controller design (§2.2) differs structurally from those reference
   projects — a deliberate, documented adaptation to the simpler
   interpreter variant, not an oversight.

## 4. Still to do

Nothing outstanding — every component (PDDL planners, both IndiGolog
controllers, the live exogenous-event demo, and all three reasoning
tasks) has now been executed for real on the course VM and its
transcripts captured above.
