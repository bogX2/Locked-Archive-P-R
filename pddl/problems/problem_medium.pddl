;; ============================================================
;; The Locked Archive -- Medium instance
;; 5 rooms, a mix of key and code locks, with one MANDATORY
;; combine step producing the key needed for the final door.
;;
;; Layout:
;;  r1 --(l1,key)--> r2 --(l2,code)--> r3 --(l3,key)--> r4 --(l4,code)--> r5 (exit)
;;
;;  key_a is in r1 and opens l1.
;;  Clue for l2 is in r1 (read before leaving the start room).
;;  item_x is in r2, item_y is in r3; combine(item_x,item_y) -> key_c,
;;  which is required to open l3. There is no other way to obtain key_c.
;;  Clue for l4 is in r4.
;; ============================================================

(define (problem locked-archive-medium)
  (:domain locked-archive-adl)   ;; swap to locked-archive-strips for the STRIPS version

  (:objects
    r1 r2 r3 r4 r5 - room
    l1 l3 - key_lock
    l2 l4 - code_lock
    key_a item_x item_y key_c - item
  )

  (:init
    (at r1)

    (connected r1 r2 l1) (connected r2 r1 l1)
    (connected r2 r3 l2) (connected r3 r2 l2)
    (connected r3 r4 l3) (connected r4 r3 l3)
    (connected r4 r5 l4) (connected r5 r4 l4)

    (needs_key l1 key_a)
    (needs_key l3 key_c)

    (item_at key_a r1)
    (item_at item_x r2)
    (item_at item_y r3)

    (combinable item_x item_y key_c)

    (clue_at l2 r1)
    (clue_at l4 r4)

    (= (move-cost l1) 1)
    (= (move-cost l2) 1)
    (= (move-cost l3) 1)
    (= (move-cost l4) 1)
    (= (total-cost) 0)
  )

  (:goal (at r5))

  (:metric minimize (total-cost))
)
