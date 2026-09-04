;; ============================================================
;; The Locked Archive -- Escape Room Solver
;; STRIPS-downgraded domain.
;;
;; Functionally equivalent to domain_adl.pddl, but the "combine"
;; action is fully grounded (?i1 ?i2 ?i3 all given as parameters,
;; "combinable" used as an ordinary positive precondition) instead
;; of relying on an existential precondition and a universally
;; quantified conditional effect. This removes every ADL construct
;; so the domain can be solved with delete-relaxation heuristics
;; such as hFF and hadd in Fast Downward, which do not support
;; conditional effects / quantifiers.
;; ============================================================

(define (domain locked-archive-strips)

  (:requirements :typing :action-costs)

  (:types
    room item lock - object
    key_lock code_lock - lock
  )

  (:predicates
    (at ?r - room)
    (connected ?r1 ?r2 - room ?l - lock)
    (unlocked ?l - lock)
    (item_at ?i - item ?r - room)
    (has ?i - item)
    (needs_key ?l - key_lock ?i - item)
    (known_code ?l - code_lock)
    (combinable ?i1 ?i2 ?i3 - item)
    (clue_at ?l - code_lock ?r - room)
  )

  (:functions
    (move-cost ?l - lock)
    (total-cost)
  )

  (:action move
    :parameters (?from ?to - room ?l - lock)
    :precondition (and
      (at ?from)
      (connected ?from ?to ?l)
      (unlocked ?l)
    )
    :effect (and
      (not (at ?from))
      (at ?to)
      (increase (total-cost) (move-cost ?l))
    )
  )

  (:action pick_up
    :parameters (?i - item ?r - room)
    :precondition (and
      (at ?r)
      (item_at ?i ?r)
    )
    :effect (and
      (not (item_at ?i ?r))
      (has ?i)
    )
  )

  ;; ----------------------------------------------------------
  ;; combine (STRIPS form): ?i1, ?i2, ?i3 are all free parameters,
  ;; grounded by the planner over every fact matching "combinable".
  ;; No conditional effect, no quantifier -- plain STRIPS action.
  ;; ----------------------------------------------------------
  (:action combine
    :parameters (?i1 ?i2 ?i3 - item)
    :precondition (and
      (has ?i1)
      (has ?i2)
      (combinable ?i1 ?i2 ?i3)
    )
    :effect (and
      (not (has ?i1))
      (not (has ?i2))
      (has ?i3)
    )
  )

  (:action read_clue
    :parameters (?l - code_lock ?r - room)
    :precondition (and
      (at ?r)
      (clue_at ?l ?r)
    )
    :effect (known_code ?l)
  )

  (:action unlock_with_key
    :parameters (?l - key_lock ?i - item)
    :precondition (and
      (needs_key ?l ?i)
      (has ?i)
    )
    :effect (unlocked ?l)
  )

  (:action unlock_with_code
    :parameters (?l - code_lock)
    :precondition (known_code ?l)
    :effect (unlocked ?l)
  )

)
