# The Locked Archive — IndiGolog Execution Transcripts

All transcripts below are real, unedited output captured from running
`indigolog_plain.pl` on the course VM. They cover both controllers on
all three problem instances, the live exogenous-event demo, and all
three reasoning tasks (Legality, Projection, Regression).

---

## 1. Easy instance

### 1.1 Simple Controller

```
?- main.
Controllers available: [simple,reactive]
Select controller: simple.
Executing controller: *simple*
pick_up(key1,r1)
unlock_with_key(l1,key1)
move(r1,r2,l1)
read_clue(l2,r2)
unlock_with_code(l2)
move(r2,r3,l2)
6 actions.
true.
```

### 1.2 Reactive Controller

```
?- main.
Controllers available: [simple,reactive]
Select controller: reactive.
Executing controller: *reactive*
start_interrupts
pick_up(key1,r1)
unlock_with_key(l1,key1)
move(r1,r2,l1)
read_clue(l2,r2)
unlock_with_code(l2)
move(r2,r3,l2)
stop_interrupts
8 actions.
true .
```

---

## 2. Medium instance

### 2.1 Simple Controller

```
?- main.
Controllers available: [simple,reactive]
Select controller: simple.
Executing controller: *simple*
pick_up(key_a,r1)
read_clue(l2,r1)
unlock_with_key(l1,key_a)
move(r1,r2,l1)
pick_up(item_x,r2)
unlock_with_code(l2)
move(r2,r3,l2)
pick_up(item_y,r3)
combine(item_x,item_y,key_c)
unlock_with_key(l3,key_c)
move(r3,r4,l3)
read_clue(l4,r4)
unlock_with_code(l4)
move(r4,r5,l4)
14 actions.
true.
```

### 2.2 Reactive Controller

```
?- main.
Controllers available: [simple,reactive]
Select controller: reactive.
Executing controller: *reactive*
start_interrupts
pick_up(key_a,r1)
read_clue(l2,r1)
unlock_with_key(l1,key_a)
move(r1,r2,l1)
pick_up(item_x,r2)
unlock_with_code(l2)
move(r2,r3,l2)
pick_up(item_y,r3)
combine(item_x,item_y,key_c)
unlock_with_key(l3,key_c)
move(r3,r4,l3)
read_clue(l4,r4)
unlock_with_code(l4)
move(r4,r5,l4)
stop_interrupts
16 actions.
true .
```

---

## 3. Hard instance

### 3.1 Simple Controller

```
?- main.
Controllers available: [simple,reactive]
Select controller: simple.
Executing controller: *simple*
pick_up(key_start,r1)
unlock_with_key(l0,key_start)
move(r1,r2,l0)
pick_up(key_w1,r2)
pick_up(key_e1,r2)
unlock_with_key(l_w1,key_w1)
move(r2,r3,l_w1)
pick_up(item_p,r3)
read_clue(l_w2,r3)
unlock_with_key(l_e1,key_e1)
unlock_with_code(l_w2)
move(r3,r4,l_w2)
pick_up(item_q,r4)
combine(item_p,item_q,key_w3)
unlock_with_key(l_w3,key_w3)
move(r4,r5,l_w3)
read_clue(l_w4,r5)
unlock_with_code(l_w4)
move(r5,r8,l_w4)
19 actions.
true.
```

### 3.2 Reactive Controller

```
?- main.
Controllers available: [simple,reactive]
Select controller: reactive.
Executing controller: *reactive*
start_interrupts
pick_up(key_start,r1)
unlock_with_key(l0,key_start)
move(r1,r2,l0)
pick_up(key_w1,r2)
pick_up(key_e1,r2)
unlock_with_key(l_w1,key_w1)
move(r2,r3,l_w1)
pick_up(item_p,r3)
read_clue(l_w2,r3)
unlock_with_key(l_e1,key_e1)
unlock_with_code(l_w2)
move(r3,r4,l_w2)
pick_up(item_q,r4)
combine(item_p,item_q,key_w3)
unlock_with_key(l_w3,key_w3)
move(r4,r5,l_w3)
read_clue(l_w4,r5)
unlock_with_code(l_w4)
move(r5,r8,l_w4)
stop_interrupts
21 actions.
true .
```

---

## 4. Live exogenous-event demo (Hard instance, Reactive Controller)

Both scripted events (`hint_revealed(l_e2)` and `door_jams(r2,r3)`)
fire before the first real action. The plan found goes straight
through the east branch, skipping `read_clue(l_e2,r6)` entirely
thanks to the hint.

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

---

## 5. Reasoning tasks (Hard instance)

### 5.1 Legality Task

`indigolog/1`, natural action order. Confirms an illegal prefix
(using a key before picking it up) is correctly rejected, and the
full legal 17-action west-branch plan is correctly accepted.

```
?- demo_legality.
=== Legality Task (hard instance) ===
As expected, [unlock_with_key(l0,key_start),move(r1,r2,l0)] is ILLEGAL from s0 (key not picked up yet).
pick_up(key_start,r1)
unlock_with_key(l0,key_start)
move(r1,r2,l0)
pick_up(key_w1,r2)
unlock_with_key(l_w1,key_w1)
move(r2,r3,l_w1)
pick_up(item_p,r3)
read_clue(l_w2,r3)
unlock_with_code(l_w2)
move(r3,r4,l_w2)
pick_up(item_q,r4)
combine(item_p,item_q,key_w3)
unlock_with_key(l_w3,key_w3)
move(r4,r5,l_w3)
read_clue(l_w4,r5)
unlock_with_code(l_w4)
move(r5,r8,l_w4)
17 actions.
As expected, the full 17-action west-branch plan IS legal from s0.
true.
```

### 5.2 Projection Task

`holds/2`, **reversed** action order (most recently executed action
first — mirrors `do(a,s)` nesting; the opposite convention from
`indigolog/1` above). Confirms `has(item_p)` holds after picking it
up, and that the agent has not yet reached the exit at that point.

```
?- demo_projection.
=== Projection Task (hard instance) ===
Projection OK: has(item_p) holds after [pick_up(key_start,r1),unlock_with_key(l0,key_start),move(r1,r2,l0),pick_up(key_w1,r2),unlock_with_key(l_w1,key_w1),move(r2,r3,l_w1),pick_up(item_p,r3)].
As expected, the agent has NOT reached the exit yet at this point.
true.
```

### 5.3 Regression Task

`search(while(neg(Goal), any_action))`. Confirms the exit-room goal
situation is reachable from the initial situation, and actually
executes the discovered plan.

```
?- demo_regression.
=== Regression Task (hard instance) ===
pick_up(key_start,r1)
unlock_with_key(l0,key_start)
move(r1,r2,l0)
pick_up(key_w1,r2)
pick_up(key_e1,r2)
unlock_with_key(l_w1,key_w1)
move(r2,r3,l_w1)
pick_up(item_p,r3)
read_clue(l_w2,r3)
unlock_with_key(l_e1,key_e1)
unlock_with_code(l_w2)
move(r3,r4,l_w2)
pick_up(item_q,r4)
combine(item_p,item_q,key_w3)
unlock_with_key(l_w3,key_w3)
move(r4,r5,l_w3)
read_clue(l_w4,r5)
unlock_with_code(l_w4)
move(r5,r8,l_w4)
19 actions.
Goal situation some(r,and(exit_room(r),at(r))) IS reachable from the initial situation.
true.
```

---

## Summary table

| Test | Result | Actions |
|---|---|---:|
| Easy — Simple | ✅ optimal | 6 |
| Easy — Reactive | ✅ optimal | 8 (incl. interrupt overhead) |
| Medium — Simple | ✅ optimal | 14 |
| Medium — Reactive | ✅ optimal | 16 (incl. interrupt overhead) |
| Hard — Simple | ✅ west branch | 19 |
| Hard — Reactive | ✅ west branch | 21 (incl. interrupt overhead) |
| Live exogenous-event demo | ✅ east branch, hint applied | 20 |
| Legality Task | ✅ correct accept/reject | — |
| Projection Task | ✅ correct | — |
| Regression Task | ✅ reachable, plan executed | 19 |
