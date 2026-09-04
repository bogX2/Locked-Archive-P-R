# The Locked Archive — Escape Room Solver

Planning and Reasoning course project.
Group member: Tutuianu Bogdan Andrei (Matricola: 2217481)

An agent is trapped inside a multi-room archive and must explore rooms,
collect items, decode clues, and unlock doors to reach the exit before
being stuck forever. The same domain is modelled twice, with two
different formalisms:

- **Part 1 — PDDL / Fast Downward** (`pddl/`): classical planning.
- **Part 2 — Situation Calculus / IndiGolog** (`indigolog/`): high-level
  agent programming with online execution and exogenous events.

## Repository layout

```
pddl/
  domain_adl.pddl              ADL domain: genuine conditional effect
                                + existential precondition in combine
  domain_strips.pddl           STRIPS-downgraded domain (hFF/hadd-compatible)
  problems/
    problem_easy.pddl          3 rooms
    problem_medium.pddl        5 rooms, 1 mandatory combine
    problem_hard.pddl          8 rooms, 2 branches of differing cost,
                                2 combine opportunities (1 on the optimal path)

indigolog/
  escape_room_domain.pl        Action theory: fluents, poss/2, causes_true/false
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
(repeat for the medium/hard instances; note the `_strips` problem files -- they
are identical to the ADL ones except for the `:domain` line, needed because
Fast Downward requires the problem's declared domain name to match the
domain file being loaded)

**All 9 runs (3 instances × 3 configurations) have been executed already**;
raw logs are in `experiment_logs/`, and the full results table is in
`RESULTS.md` at the repository root. Headline finding: on the hard instance,
Blind search (exhaustive, admissible) correctly finds the cost-optimal
west-branch plan (cost 13), while hFF and hadd — both inadmissible on this
domain — instead settle for the shorter-but-more-expensive east-branch plan
(cost 16, 12 actions vs. the optimal 17). The same effect shows up on the
medium instance: hadd returns a cost-6 plan instead of the optimal cost-4
one. This is a genuine, reproducible illustration of why an inadmissible
heuristic can trade solution optimality for search speed — see `RESULTS.md`
for the full numbers and discussion.

## Part 2 — Situation Calculus & IndiGolog

Fluents mirror the PDDL predicates one-to-one: `at/1`, `has/1`,
`item_at/2`, `unlocked/1`, `known_code/1`, plus `blocked/2` (needed for
the `door_jams` exogenous event) and a bookkeeping `depth_used/1`.
Static world-map facts (`connected/3`, `needs_key/2`, `combinable/3`,
`clue_at/2`) are loaded per instance and are **not** fluents.

### Controllers

- **Simple Controller** (`control_simple`): a single depth-bounded
  offline `search/1` over the nondeterministic `escape_task` program,
  executed once found. No reaction to events arriving mid-plan.
- **Reactive Controller** (`control_reactive`): `prioritized_interrupts/1`
  re-evaluates the situation before every single primitive action —
  highest priority stops as soon as the goal holds, otherwise it
  re-searches for just one more action from the *current* (possibly
  exogenously updated) situation and recurses. This is what makes it
  adapt to `hint_revealed` (skips the now-unnecessary `read_clue`,
  for free, via the successor state axiom) and to `door_jams`
  (reroutes from the west branch to the east branch on the hard
  instance) without any hand-written special-case branching logic.

### Reasoning tasks (`reasoning_tasks.pl`)

Self-contained situation-term evaluator (`s0` / `do(A,S)`) demonstrating:

- **Legality** — is a given action sequence executable step by step
  from `s0`? (e.g. `unlock_with_key` before the matching `pick_up`
  correctly comes out illegal).
- **Projection** — does a fluent hold after executing a given sequence?
- **Regression** — regress a goal formula back through a sequence to a
  formula over `s0` only, then check it there, to certify reachability.

### Live demo (`demo_exog_harness.pl`)

Scripts `hint_revealed(l_w2)` after 2 actions and `door_jams(r3,r4)`
after 4 actions during a `control_reactive` run on the hard instance,
to show both reactive behaviours live. **The exact hook used to feed
simulated exogenous events into the interpreter's main loop varies
between IndiGolog distributions** — two alternative integration points
are sketched in the file; keep whichever matches the interpreter
installed on the course VM.

### Known interpreter gotchas (worth keeping in the slides)

- `initialize(evaluator)` **must** be called before the first
  `indigolog(...)` call in a fresh session, or the evaluator throws
  "undefined procedure" errors.
- `pi/2` calls must be **nested** (`pi(X, pi(Y, Body))`), never passed
  a variable list (`pi([X,Y], Body)`) — the latter is accepted by the
  Prolog parser but does not bind as expected.
- Depth-bounded search (`depth_used`/`max_depth`) is required, or
  `star(any_action)` inside an offline `search/1` can cycle forever
  alternating `move`/`move back`.
- The boilerplate declarations `fun_fluent(_) :- fail.` and
  `cache(_) :- fail.` are mandatory even though the domain uses no
  functional fluents or caching — omitting them breaks the evaluator.
- **Querying a fluent with an unbound argument** (e.g. "which items do
  I currently hold?", `has(I)` with `I` free) through a
  causes_true/causes_false-style successor-state axiom needs care: a
  naive implementation that cuts as soon as `causes_true` produces any
  match will only return the instance tied to the *most recent* action
  and silently miss instances that persisted via the frame axiom. This
  was caught while building the standalone reachability checker in
  `_dev_only_validation.pl` (see below) — every instance there is now
  enumerated ground-first (from the static `item/1`/`room/1`
  declarations) precisely to sidestep this.
- **Branch "cost" does not transfer directly from PDDL to IndiGolog.**
  On the hard instance, the west branch is cheaper *in PDDL move-cost*
  (13 vs. 16) but actually needs *more primitive actions* (17 vs. 12)
  once the mandatory combine's extra `pick_up`/`combine`/`unlock`
  steps are counted — because IndiGolog's plain depth-bounded search
  has no per-action cost metric to mirror `move-cost`. `max_depth` in
  `instance_hard.pl` is therefore set generously (20) so both branches
  are individually reachable, rather than tightened to imitate the
  PDDL cost preference — see `instance_hard.pl` for the full note.

### Validation performed in this environment

`_dev_only_validation.pl` is a small standalone reachability checker
(ground depth-bounded DFS over the same `poss`/`causes_true` theory
used by `reasoning_tasks.pl`) that does **not** depend on the official
IndiGolog interpreter, and was used to confirm all three instances are
solvable and that `escape_room_domain.pl` has no logical errors, ahead
of testing on the course VM's real interpreter:

| Instance | Minimal plan found | Length |
|---|---|---|
| Easy   | `pick_up, unlock_with_key, move, read_clue, unlock_with_code, move` | 6 |
| Medium | (14-step plan through the mandatory combine)                        | 14 |
| Hard, west branch | (17-step plan through the mandatory combine)          | 17 |
| Hard, east branch | (12-step plan, no combine needed)                     | 12 |

Legality, Projection and Regression demos in `reasoning_tasks.pl` were
also re-run against the hard instance and produce the expected results
(illegal-before-pick_up sequence correctly rejected, projected/regressed
fluents match hand-computed values).

## Deliberate deviation from the original proposal

The original proposal listed a numeric fluent `time_remaining` with a
`time_cost(action)` function and a `total-cost` metric. **`time_remaining`
was dropped**: Fast Downward does not support a decreasing numeric
*precondition* of that shape without additional PDDL extensions outside
the taught subset, and keeping it would have blocked heuristic search
entirely.

It is replaced by the standard `:action-costs` pattern: a single
`total-cost` function increased by a **`move-cost` value that differs
per lock/door** (see `problem_hard.pddl`, where west-branch doors cost
3 and east-branch doors cost 5). This achieves the same design goal as
the original proposal — forcing the planner to discard an inefficient
route under a resource constraint — with a formulation Fast Downward
and its heuristics fully support, and it composes cleanly with
`:metric minimize (total-cost)`. On the IndiGolog side the same idea is
realised as move-count-based depth bounding (`depth_used` / `max_depth`)
rather than a numeric budget, since the interpreter has no native
action-cost metric; see the comment in `instance_hard.pl`.

## Suggested next steps

1. Run all (instance × search configuration) combinations on the course
   VM and fill in the comparison table for the PDDL slides.
2. Run `main_easy.pl`, `main_medium.pl`, `main_hard.pl` with both
   controllers on the course VM's IndiGolog interpreter; adjust the
   `demo_exog_harness.pl` integration point to match the installed
   interpreter version.
3. Push everything to the GitHub repository together with the SVG maps
   already generated for the three PDDL instances.
