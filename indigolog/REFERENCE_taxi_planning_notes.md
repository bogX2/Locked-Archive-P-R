# Reference notes — "taxi_planning" (Ragaglia & Di Nola)

Extracted from `taxi_planning-main.zip`, a classmate's project for the same
course. Kept here as a working reference for **The Locked Archive**,
especially for Part 2 (IndiGolog) implementation questions.

## Why this matters

This is a project that was **actually run on the course's real IndiGolog
interpreter** (not just written) — the README shows real terminal output
from legality/projection/regression tasks. It's the best available ground
truth for "does this syntax actually work on our course VM?" questions.

## 1. How they invoke the interpreter

```
swipl indigolog/config.pl taxi/main.pl
```

`main.pl` loads the interpreter via a **shared `dir/2` + `consult/1`
mechanism**, not plain `['file.pl']` includes:

```prolog
:- dir(indigolog, F), consult(F).
:- dir(eval_bat, F), consult(F).    % after interpreter always!
:- [taxi].
```

`dir(Name, Path)` and `config.pl` are course-provided infrastructure (not
included in their repo, presumably shared by everyone in the course) — this
is very likely what's already set up on **your** course VM too. Worth
checking whether the VM expects the same `config.pl` + `dir/2` pattern
rather than direct `['escape_room_domain.pl']` consults.

## 2. ⚠️ pi/2 syntax — contradicts our own notes

Their code uses **pi/2 with a list of variables**, and it is confirmed
working (per their README's real run output):

```prolog
proc(pi_move, pi([l1, l2], move(l1, l2))).
proc(pi_pickup, pi([p, l], pickUp(p, l))).
```

This directly contradicts the assumption written into
`controllers.pl` for Locked Archive ("pi/2 must be nested, e.g.
`pi(X, pi(Y, Body))` — passing a variable list is silently wrong"). Our
nested version is still safe either way, but **it's worth testing the list
form directly on the course VM** — if it works, it may be a slightly
cleaner style, and it's useful to know which claim is actually true for
*our* interpreter instance before repeating either claim in the
presentation Q&A.

## 3. Confirmed-working interpreter constructs (from `taxi.pl`)

- `fun_fluent(F)` / `rel_fluent(F)` declarations (ours only needs
  `rel_fluent`, since Locked Archive has no functional fluents)
- `causes_true(Action, Fluent, Cond)` / `causes_false(...)` — same pattern
  we use
- `causes_val(Action, FunctionalFluent, NewValue, Cond)` — for functional
  fluents (e.g. `battery_level`, `total_cost`); not needed for Locked
  Archive but good to know the exact syntax if it ever comes up in Q&A
- `poss(Action, Cond)` — same pattern we use
- **Existential quantification in conditions uses `some(V, Cond)`**, e.g.
  `neg(some(j, on_taxi(j)))` — if we ever need "no other passenger is on
  the taxi"-style conditions in IndiGolog (we don't currently, but useful
  vocabulary for Q&A)
- `cache(_) :- fail.` boilerplate confirmed present, matching our notes.
  Interestingly **no `fun_fluent(_) :- fail.` catch-all appears** in their
  file — but they *do* declare real functional fluents (`battery_level`,
  `total_cost`), so it's not a counter-example to our "mandatory
  boilerplate" note; a domain with zero functional fluents (like ours)
  still needs the catch-all so the interpreter's internal checks don't
  error on an undefined `fun_fluent/1`.
- Control constructs confirmed working: `star`, `pi`, `ndet`, `while`,
  `if`, `search`, `prioritized_interrupts`, plus two we don't currently
  use: `gexec(Cond, Program)` (guarded execution) and `unset(Fluent)`
  (used together in their reactive controller to reset a "has_changed"
  flag before re-searching — a clean pattern worth knowing about).

## 4. Reasoning tasks — the interpreter provides `eval/3` directly

Their `projection_task/0` calls the interpreter's **built-in** `eval/3`
predicate rather than a hand-rolled evaluator:

```prolog
projection_task :-
    read(COND), read(SEQ),
    ( eval(COND, SEQ, true)
    -> format("Condition ~w HOLDS after executing ~w~n", [COND, SEQ])
    ;  format("Condition ~w DOES NOT HOLD...~n", [COND, SEQ])
    ).
```

**This means the real interpreter already ships a projection/regression
evaluator** — our `reasoning_tasks.pl` (a from-scratch situation-term
evaluator) was built because the actual interpreter wasn't available in
this sandbox to test against. Once on the course VM, it's worth checking
whether `eval/3` can be used directly instead of / alongside our own
version — could simplify the Legality/Projection/Regression demo
significantly, or at least serve as a cross-check.

Their **regression task** pattern is also worth knowing — they don't
regress a formula symbolically; instead they search for a path to the goal
condition directly:

```prolog
regression_task :-
    read(end_state),
    ( indigolog(search([star(random_action), ?(end_state)]))
    -> format("Goal situation ~w IS reachable...~n", [end_state])
    ;  format("...is NOT reachable...~n", [end_state])
    ).
```

i.e. "regression" here is answered by *search* (does some prefix of
`random_action*` reach a state satisfying the goal condition?), leaning on
the interpreter's `search/1`, rather than symbolic regression through
successor-state axioms. Simpler to implement, though it doesn't produce
the regressed formula itself the way a textbook regression operator would
— worth mentioning both approaches exist if asked in Q&A about how
regression was implemented.

## 5. PDDL side note

Their `domain.pddl` (taxi domain) also uses `:adl` + conditional effects
(`when`) for traffic-light switching and congestion-based cost, plus
`:action-costs`. Broadly the same spirit as our ADL `combine` action.
They used **ENHSP** (not just Fast Downward) for some heuristic
configurations (`-h hmax -s Greedy`, etc.) — an alternative planner in
case Fast Downward alone feels thin for the "Planners and Search
Heuristics" section, though not necessary for us since our own Blind vs.
hFF vs. hadd comparison already makes the intended point.

## 6. Takeaways for the presentation Q&A prep

If asked "how confident are you the code runs on the real interpreter":
- Be upfront that Locked Archive's IndiGolog files were validated with a
  standalone Prolog evaluator (domain logic confirmed correct/solvable)
  but not yet run on the actual interpreter, since it isn't available
  outside the course VM.
- Mention this reference project as evidence of what real working syntax
  looks like on the course's interpreter, and that our domain follows the
  same conventions (`rel_fluent`, `causes_true/false`, `poss`, `proc`).
- If asked specifically about `pi/2`, mention both forms have been seen
  (nested vs. list) and that this should be confirmed on the VM before the
  final submission.
