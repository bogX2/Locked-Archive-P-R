# The Locked Archive — Escape Room Solver

Planning and Reasoning course project.
Group member: Tutuianu Bogdan Andrei (Matricola: 2217481)

An agent is trapped inside a multi-room archive and must explore rooms,
collect items, decode clues, and unlock doors to reach the exit. The same
domain is modelled twice, with two different formalisms:

- **Part 1 — PDDL / Fast Downward** (`pddl/`): classical planning.
- **Part 2 — Situation Calculus / IndiGolog** (`indigolog/`): high-level
  agent programming with online execution and exogenous events.

Both parts are complete and have been executed for real (Fast Downward
built from source; IndiGolog run on the course VM's `indigolog_plain.pl`
interpreter). Full results and raw logs/transcripts are in `RESULTS.md`
and `indigolog_transcripts.md`.

## Repository layout

```
pddl/
  domain_adl.pddl              ADL domain: genuine conditional effect
                                + existential precondition in combine
  domain_strips.pddl           STRIPS-downgraded domain (hFF/hadd-compatible)
  problems/
    problem_easy.pddl          3 rooms                (+ _strips variant)
    problem_medium.pddl        5 rooms, 1 mandatory combine (+ _strips variant)
    problem_hard.pddl          8 rooms, 2 branches of differing cost,
                                2 combine opportunities (+ _strips variant)
  experiment_logs/              Raw Fast Downward output for all 9 runs

indigolog/
  escape_room_domain.pl        Action theory: prim_fluent/causes_val
                                (indigolog_plain.pl convention), poss/2
  controllers.pl                Simple Controller + Reactive Controller
  instances/
    instance_easy.pl
    instance_medium.pl
    instance_hard.pl
  main_easy.pl                  Entry point (loads domain+controllers+instance)
  main_medium.pl
  main_hard.pl
  reasoning_tasks.pl            Legality / Projection / Regression demos
  demo_exog_harness.pl          Scripted exogenous events for the live demo
  REFERENCE_taxi_planning_notes.md   Notes from a classmate's reference project

RESULTS.md                     Full experimental results (PDDL + IndiGolog)
indigolog_transcripts.md       Raw, unedited execution transcripts (course VM)
slides/                        Presentation assets (room-layout SVG maps)
```

## Part 1 — PDDL

### Domain

Types: `room`, `item`, `lock` (subtypes `key_lock`, `code_lock`).

Predicates: `at`, `connected`, `unlocked`, `item_at`, `has`, `needs_key`,
`known_code`, `combinable`, `clue_at`.

Actions: `move`, `pick_up`, `combine`, `read_clue`, `unlock_with_key`,
`unlock_with_code`.

Two versions of the domain are provided:

- `domain_adl.pddl` — the `combine` action takes only two parameters
  (`?i1 ?i2`); which item is produced is decided by a universally
  quantified **conditional effect** (`forall`/`when`) driven by the
  static `combinable` relation, guarded by an **existential
  precondition** that some valid combination exists. This is the
  genuinely ADL part of the model.
- `domain_strips.pddl` — the same action fully grounded
  (`?i1 ?i2 ?i3` all parameters, `combinable` as a plain positive
  precondition), with no conditional effects or quantifiers, so that
  delete-relaxation heuristics that don't support ADL (hFF, hadd) can
  be used.

### Problem instances

| Instance | Rooms | Notes |
|---|---|---|
| Easy   | 3 | 1 key lock, 1 code lock, no combine step. Sanity check. |
| Medium | 5 | 1 mandatory combine (`item_x + item_y -> key_c`) required to reach the exit. |
| Hard   | 8 | Hub room branches into a cheap west path (mandatory combine, move-cost 3/door) and an expensive east path (decoy combine, move-cost 5/door). Cost-optimal plan = west branch. |

### Planners / heuristics

Run with Fast Downward, comparing:

- **Blind search** — baseline, only usable directly on `domain_adl.pddl`
  (compatible with conditional effects).
- **hFF** / **hadd** — usable only on `domain_strips.pddl` after the ADL
  downgrade, since Fast Downward's delete-relaxation heuristics do not
  support conditional effects or quantifiers.

```
./fast-downward.py domain_adl.pddl    problems/problem_easy.pddl   --search "astar(blind())"
./fast-downward.py domain_strips.pddl problems/problem_easy_strips.pddl --search "astar(ff())"
./fast-downward.py domain_strips.pddl problems/problem_easy_strips.pddl --search "astar(add())"
```
(repeat for the medium/hard instances; note the `_strips` problem files — they
are identical to the ADL ones except for the `:domain` line, needed because
Fast Downward requires the problem's declared domain name to match the
domain file being loaded)

**All 9 runs (3 instances × 3 configurations) have been executed.** Raw
logs are in `experiment_logs/`, full table and discussion in `RESULTS.md`.
Headline finding: on the hard instance, Blind search (exhaustive,
admissible) correctly finds the cost-optimal west-branch plan (cost 13),
while hFF and hadd — both inadmissible on this domain — instead settle
for the shorter-but-more-expensive east-branch plan (cost 16, 12 actions
vs. the optimal 17). The same effect shows up on the medium instance:
hadd returns a cost-6 plan instead of the optimal cost-4 one. This is a
genuine, reproducible illustration of why an inadmissible heuristic can
trade solution optimality for search speed — see `RESULTS.md` for the
full numbers.

## Part 2 — Situation Calculus & IndiGolog

Written for the course's **`indigolog_plain.pl`** interpreter specifically
(not the fuller `indigolog.pl` + `eval_bat.pl` stack used by some
reference projects — see "Known interpreter gotchas" below for why this
matters).

Fluents mirror the PDDL predicates one-to-one: `at/1`, `has/1`,
`item_at/2`, `unlocked/1`, `known_code/1`, plus `blocked/2` (needed for
the `door_jams` exogenous event) and `last_room/1` (anti-cycle guard).
Static world-map facts (`connected/3`, `needs_key/2`, `combinable/3`,
`clue_at/2`) are loaded per instance and are **not** fluents.

### Controllers

- **Simple Controller** (`control_simple`): a single offline `search/1`
  over the nondeterministic `escape_task` program, executed once found.
  No reaction to events arriving mid-plan.
- **Reactive Controller** (`control_reactive`): `prioritized_interrupts/1`
  re-searches the full remaining task (`search(escape_task)`) whenever the
  goal is not yet reached, from the *current* (possibly exogenously
  updated) situation. This is what lets it skip a `read_clue` after a
  `hint_revealed` event, or plan through the east branch entirely when
  `door_jams` blocks the west one — with no hand-written special-case
  branching logic.

Both controllers reliably solve all three instances (see `RESULTS.md`,
§2.1). On the hard instance, both occasionally pick up the east-branch
key `key_e1` and unlock `l_e1` along the way without ever using it — a
harmless detour, not a bug: IndiGolog's plain `search/1` has no numeric
cost metric to prefer the west branch the way Fast Downward's
differentiated `move-cost` does (see "Deliberate deviation" below).

### Reasoning tasks (`reasoning_tasks.pl`)

Using the real interpreter's own `indigolog/1`, `holds/2` and `search/1`
predicates (not a hand-rolled evaluator):

- **Legality** (`demo_legality`) — `indigolog/1` executes a sequence for
  real from `s0`; fails if any action is illegal at the point it's
  attempted. Includes both a legal example (full 17-action west-branch
  plan) and an **illegal example** (`unlock_with_key` before the matching
  `pick_up` — correctly rejected).
- **Projection** (`demo_projection`) — `holds/2` is a pure query (no
  execution, no side effects) that checks a fluent after a sequence.
  **Important**: it takes the action sequence in **reversed** order
  (most recently executed action first, mirroring `do(a,s)` nesting) —
  the opposite convention from `indigolog/1`, and an easy detail to get
  backwards.
- **Regression** (`demo_regression`) — `search(while(neg(Goal),
  any_action))` checks whether a goal situation is reachable from the
  current situation, and executes the plan if one is found. The positive
  case (exit room reachable) is demonstrated live. A genuinely
  **unreachable** goal is **not** executed live on this domain: `last_room/1`
  only blocks an *immediate* bounce-back, not longer cycles, so an
  unreachable goal is not guaranteed to terminate under unbounded search
  — documented as a known limitation rather than risking a hung demo
  (the same call made by the reference Sokoban project for the identical
  reason).

Interactive, course-style versions (`legality_task/0`, `projection_task/0`,
`regression_task/0`) that read the sequence/condition from the console are
also provided, mirroring the `taxi_planning` reference project's own
predicates of the same name.

### Live demo (`demo_exog_harness.pl`)

Scripts `hint_revealed(l_e2)` and `door_jams(r2,r3)` to fire **before**
the first real action of a `control_reactive` run on the hard instance.
Full transcript in `RESULTS.md` §2.2 / `indigolog_transcripts.md` §4.
Both mechanisms are confirmed working: the code becomes known without
ever calling `read_clue`, and the west branch is never explored at all
once blocked.

Events fire upfront (not mid-plan) by design: `indigolog_plain.pl` has
no `gexec`/`unset` (confirmed absent from both its own source and
`lib/common.pl` — those constructs belong to the fuller `indigolog.pl` +
`eval_bat.pl` stack that `sokoban.pl`/`taxi.pl` load instead). Firing
events before the first action sidesteps the need for a mid-execution
abort/restart entirely while still genuinely exercising both mechanisms.

### Known interpreter gotchas (real bugs found and fixed)

Every item below was diagnosed from an actual error or a live stuck/looping
session on the course VM, then confirmed fixed by re-running. Full detail
in `RESULTS.md` §3; summary:

1. `initialize.` is arity 0 in `indigolog_plain.pl` — `initialize(evaluator)`
   is an `eval_bat.pl`-only convention.
2. `exog_occurs/1` takes a single action and must **fail** when nothing
   happens (not succeed with an empty list).
3. Successor state axioms must use **`prim_fluent/1` + `causes_val/4`**
   — `rel_fluent/1` + `causes_true/3`/`causes_false/3` (the `eval_bat.pl`
   convention) is silently never applied by `indigolog_plain.pl`'s own
   projector, which caused an early infinite `pick_up` loop.
4. `execute/2` is a mandatory hook (delegating to `ask_execute/2`) —
   missing it is a separate bug from #3, surfacing only once an action is
   actually committed rather than just checked.
5. Derived conditions (e.g. `goal_reached`) must be `proc/2` abbreviations,
   not plain Prolog `:-` rules, or `search/1`'s internal lookahead never
   sees them as true.
6. Negation alone never binds a variable — every action template needs a
   positive grounding test (`?(item(i))`) before a negative guard
   (`?(neg(has(i)))`).
7. `star(E), ?(Goal)` can wander straight past an already-reached goal;
   `while(neg(Goal), E)` checks the condition before every step instead.
8. `gexec`/`unset`/`set` are not part of `indigolog_plain.pl` — confirmed
   by reading its source and `lib/common.pl` directly. This is why the
   Reactive Controller here re-searches the full task on every interrupt
   cycle instead of using the abort/restart pattern seen in
   `sokoban.pl`/`taxi.pl` (see `REFERENCE_taxi_planning_notes.md`).

**Note on `pi/2` syntax**: this project uses nested `pi/2` calls
(`pi(X, pi(Y, Body))`), confirmed safe. The `taxi_planning` reference
project instead uses `pi/2` with a list of variables
(`pi([X,Y], Body)`) and reports it working on the real course
interpreter — so the list form is not necessarily broken, just untested
here. See `REFERENCE_taxi_planning_notes.md` for details.

### Validation performed

Every component — both PDDL planners, both IndiGolog controllers, the
live exogenous-event demo, and all three reasoning tasks — has been
executed for real on the course VM. Raw, unedited transcripts are in
`indigolog_transcripts.md`; the accompanying discussion and summary
tables are in `RESULTS.md`.

## Deliberate deviations from the original proposal

**PDDL**: the original proposal listed a numeric fluent `time_remaining`
with a `time_cost(action)` function and a `total-cost` metric.
`time_remaining` was dropped: Fast Downward does not support a decreasing
numeric *precondition* of that shape without additional PDDL extensions
outside the taught subset, and keeping it would have blocked heuristic
search entirely. It is replaced by the standard `:action-costs` pattern:
a single `total-cost` function increased by a **`move-cost` value that
differs per lock/door** (west-branch doors cost 3, east-branch doors cost
5). This achieves the same design goal — forcing the planner to discard
an inefficient route — with a formulation Fast Downward fully supports.

**IndiGolog**: the interpreter has no native action-cost metric to mirror
PDDL's `move-cost`, so "branch cost" does not transfer directly between
the two formalisms. On the hard instance, the west branch is cheaper *in
PDDL move-cost* (13 vs. 16) but needs *more primitive actions* (17 vs. 12)
once the mandatory combine's extra `pick_up`/`combine`/`unlock` steps are
counted. Both branches are individually reachable by `search/1`; which
one a given run finds first depends on search/backtracking order, not on
the PDDL cost model — this is discussed explicitly rather than
papered over, since it's a genuine and instructive difference between the
two formalisms.

## Project status

Complete. Both parts (PDDL and IndiGolog) are implemented, executed, and
documented with real logs/transcripts. See `RESULTS.md` and
`indigolog_transcripts.md` for the full experimental record.
