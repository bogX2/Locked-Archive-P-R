;; ============================================================
;; The Locked Archive -- Easy instance
;; 3 rooms, 1 key lock, 1 code lock, no combine step required.
;; Used to validate the base model.
;;
;; Layout:
;;   r1 --(l1, key_lock)--> r2 --(l2, code_lock)--> r3 (exit)
;; ============================================================

(define (problem locked-archive-easy-strips)
  (:domain locked-archive-strips)   ;; swap to locked-archive-strips for the STRIPS version

  (:objects
    r1 r2 r3 - room
    l1 - key_lock
    l2 - code_lock
    key1 - item
  )

  (:init
    (at r1)

    (connected r1 r2 l1)
    (connected r2 r1 l1)
    (connected r2 r3 l2)
    (connected r3 r2 l2)

    (needs_key l1 key1)
    (item_at key1 r1)

    (clue_at l2 r2)

    (= (move-cost l1) 1)
    (= (move-cost l2) 1)
    (= (total-cost) 0)
  )

  (:goal (at r3))

  (:metric minimize (total-cost))
)
