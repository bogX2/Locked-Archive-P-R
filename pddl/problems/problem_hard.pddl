;; ============================================================
;; The Locked Archive -- Hard instance
;; 8 rooms in a non-linear layout with two alternative branches
;; leading to the exit, of differing total move-cost, and two
;; possible combine opportunities -- only one of which lies on
;; the cost-optimal path. A cost-sensitive planner must discard
;; the more expensive (and combine-free) east branch in favour
;; of the cheaper west branch, which requires solving the
;; genuine combine puzzle.
;;
;; Layout:
;;                              r3 --(l_w1)--> r4 --(l_w2)--> ... (west, cheap, mandatory combine)
;;                             /
;;   r1 --(l0)--> r2 (hub) ---
;;                             \
;;                              r6 --(l_e1)--> r7 --(l_e2)--> ... (east, expensive, decoy combine)
;;
;; West branch (cheap, cost 3 per door):
;;   r2 -l_w1(key,key_w1)-> r3 -l_w2(code)-> r4 -l_w3(key,key_w3)-> r5 -l_w4(code)-> r8 (exit)
;;   key_w3 is NOT lying anywhere: it must be produced by combining
;;   item_p (in r3) with item_q (in r4). This combine is MANDATORY
;;   on the optimal path.
;;
;; East branch (expensive, cost 5 per door):
;;   r2 -l_e1(key,key_e1)-> r6 -l_e2(code)-> r7 -l_e3(key,key_e3)-> r8 (exit)
;;   key_e3 can simply be picked up in r7 -- no combine is needed here.
;;   item_m (in r6) and item_n (in r7) can optionally be combined into
;;   bonus_item, but bonus_item is not required to open any lock: this
;;   is the decoy combine opportunity that does NOT lie on the optimal
;;   path (and the east branch itself is more expensive overall).
;;
;; West total cost = 1 (l0) + 3+3+3+3 = 13
;; East total cost = 1 (l0) + 5+5+5   = 16
;; ============================================================

(define (problem locked-archive-hard)
  (:domain locked-archive-adl)   ;; swap to locked-archive-strips for the STRIPS version

  (:objects
    r1 r2 r3 r4 r5 r6 r7 r8 - room
    l0 l_w1 l_w3 l_e1 l_e3 - key_lock
    l_w2 l_w4 l_e2 - code_lock
    key_start key_w1 item_p item_q key_w3
    key_e1 item_m item_n key_e3 bonus_item - item
  )

  (:init
    (at r1)

    ;; entry corridor
    (connected r1 r2 l0) (connected r2 r1 l0)

    ;; west branch (cheap, mandatory combine)
    (connected r2 r3 l_w1) (connected r3 r2 l_w1)
    (connected r3 r4 l_w2) (connected r4 r3 l_w2)
    (connected r4 r5 l_w3) (connected r5 r4 l_w3)
    (connected r5 r8 l_w4) (connected r8 r5 l_w4)

    ;; east branch (expensive, decoy combine)
    (connected r2 r6 l_e1) (connected r6 r2 l_e1)
    (connected r6 r7 l_e2) (connected r7 r6 l_e2)
    (connected r7 r8 l_e3) (connected r8 r7 l_e3)

    ;; key requirements
    (needs_key l0 key_start)
    (needs_key l_w1 key_w1)
    (needs_key l_w3 key_w3)
    (needs_key l_e1 key_e1)
    (needs_key l_e3 key_e3)

    ;; item placement
    (item_at key_start r1)
    (item_at key_w1 r2)
    (item_at item_p r3)
    (item_at item_q r4)
    (item_at key_e1 r2)
    (item_at item_m r6)
    (item_at item_n r7)
    (item_at key_e3 r7)

    ;; combine recipes (west = mandatory, east = decoy)
    (combinable item_p item_q key_w3)
    (combinable item_m item_n bonus_item)

    ;; clues
    (clue_at l_w2 r3)
    (clue_at l_w4 r5)
    (clue_at l_e2 r6)

    ;; differentiated move costs (west cheap, east expensive)
    (= (move-cost l0) 1)
    (= (move-cost l_w1) 3)
    (= (move-cost l_w2) 3)
    (= (move-cost l_w3) 3)
    (= (move-cost l_w4) 3)
    (= (move-cost l_e1) 5)
    (= (move-cost l_e2) 5)
    (= (move-cost l_e3) 5)
    (= (total-cost) 0)
  )

  (:goal (at r8))

  (:metric minimize (total-cost))
)
