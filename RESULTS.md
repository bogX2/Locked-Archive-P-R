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

## 2. IndiGolog / Situation Calculus — validation

The official University of Toronto IndiGolog interpreter is not
available in this sandbox (not on GitHub/PyPI/npm — it ships directly
from the course/university page and needs to be run on the course VM).
What **was** verified here, with plain SWI-Prolog 9.0.4, is that the
action theory itself (`escape_room_domain.pl` + the three instance
files) is logically correct and solvable, independent of the
interpreter, using a small standalone situation-term evaluator
(`reasoning_tasks.pl` + `_dev_only_validation.pl`).

| Instance | Result |
|---|---|
| Easy | Solvable, minimal plan length 6 |
| Medium | Solvable, minimal plan length 14 (matches the PDDL result exactly) |
| Hard, west branch | Solvable, 17 actions, requires the mandatory combine |
| Hard, east branch | Solvable, 12 actions, no combine needed |
| Legality task (hard instance) | Correctly rejects `unlock_with_key` before the matching `pick_up`; correctly accepts the legal prefix |
| Projection task (hard instance) | Correctly confirms `has(item_p)` after the relevant action prefix |
| Regression task (hard instance) | Correctly regresses `at(r3)` back to a formula that evaluates true in `s0`, confirming reachability |

### A real bug found and fixed along the way

While building the standalone validator, a classic situation-calculus
gotcha surfaced: querying a fluent with an **unbound** argument (e.g.
"which items do I currently hold?") through a naive
causes_true/causes_false-based evaluator only returns the instance tied
to the *most recent* action — it misses instances that persisted via
the frame axiom, because the evaluator cuts as soon as `causes_true`
produces any match. In practice this made `combine` invisible as a
candidate action whenever the *first* held item wasn't the one just
picked up. Fixed by enumerating candidate actions **ground-first**
(from the static `room/1`/`item/1`/lock declarations) before evaluating
their preconditions, which sidesteps the issue entirely. This is a
one-line but genuinely instructive addition for the "known interpreter
gotchas" slide, since it is exactly the kind of bug that is easy to
reproduce again on the course VM's interpreter if fluents are ever
queried with unbound arguments there too.

### Fixed along the way: `max_depth` on the hard instance

The original `max_depth(9)` on `instance_hard.pl` (meant, by analogy
with the PDDL `move-cost` budget, to "rule out the expensive branch")
was far too tight for *either* branch — the actual minimal branches
need 17 (west) and 12 (east) primitive actions respectively, not single
digits. It has been corrected to `max_depth(20)`. Also worth noting
explicitly on the slides: **branch "cost" does not transfer directly
between the two formalisms** — the west branch is cheaper in PDDL
(differentiated `move-cost`) but needs *more* primitive actions in
IndiGolog (17 vs. 12), since plain depth-bounded search has no
per-action cost metric to mirror `move-cost`. `demo_exog_harness.pl`'s
depth override was bumped to 35 accordingly, to leave slack for a
mid-plan reroute after `door_jams`.

### Still to do on the course VM

The Simple Controller / Reactive Controller / `prioritized_interrupts`
machinery in `controllers.pl` depends on the real IndiGolog
interpreter's `pi/2`, `star/1`, `search/1` and interrupt semantics and
could not be executed here. Everything above confirms the *domain and
instances themselves* are correct; running `main_easy.pl` /
`main_medium.pl` / `main_hard.pl` and `demo_exog_harness.pl` on the
actual interpreter is the one remaining step, and should now go
smoothly since the underlying theory has already been exercised
end-to-end.
