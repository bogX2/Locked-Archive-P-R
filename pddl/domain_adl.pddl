;; ============================================================
;; The Locked Archive -- Escape Room Solver
;; ADL domain (genuine conditional effects + existential precondition
;; in the "combine" action).
;;
;; The agent is trapped in a multi-room archive. It must move between
;; rooms through key-locked or code-locked doors, pick up items, read
;; clues to learn numeric codes, and combine items it is carrying to
;; produce new items required by some locks.
;; ============================================================

(define (domain locked-archive-adl)

  (:requirements :typing :adl :action-costs)

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

  ;; ----------------------------------------------------------
  ;; move: travel between two rooms through an already unlocked
  ;; lock. The cost of moving depends on which door is used
  ;; (differentiated move-cost values replace the originally
  ;; proposed time_remaining precondition, see project README).
  ;; ----------------------------------------------------------
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

  ;; ----------------------------------------------------------
  ;; pick_up: collect an item lying in the current room.
  ;; ----------------------------------------------------------
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
  ;; combine: the agent hands over two items it is carrying; the
  ;; identity of the resulting item is NOT chosen by the agent but
  ;; determined by the static "combinable" relation. This is
  ;; expressed with an existential precondition (some valid
  ;; combination exists) plus a universally quantified conditional
  ;; effect (only the item(s) matching "combinable" actually
  ;; appear) -- the genuine ADL feature of this domain.
  ;; ----------------------------------------------------------
  (:action combine
    :parameters (?i1 ?i2 - item)
    :precondition (and
      (has ?i1)
      (has ?i2)
      (exists (?i3 - item) (combinable ?i1 ?i2 ?i3))
    )
    :effect (and
      (not (has ?i1))
      (not (has ?i2))
      (forall (?i3 - item)
        (when (combinable ?i1 ?i2 ?i3)
          (has ?i3)
        )
      )
    )
  )

  ;; ----------------------------------------------------------
  ;; read_clue: while in the room holding the clue for a code
  ;; lock, learn the numeric code.
  ;; ----------------------------------------------------------
  (:action read_clue
    :parameters (?l - code_lock ?r - room)
    :precondition (and
      (at ?r)
      (clue_at ?l ?r)
    )
    :effect (known_code ?l)
  )

  ;; ----------------------------------------------------------
  ;; unlock_with_key: open a key lock using a carried item.
  ;; ----------------------------------------------------------
  (:action unlock_with_key
    :parameters (?l - key_lock ?i - item)
    :precondition (and
      (needs_key ?l ?i)
      (has ?i)
    )
    :effect (unlocked ?l)
  )

  ;; ----------------------------------------------------------
  ;; unlock_with_code: open a code lock once the code is known.
  ;; ----------------------------------------------------------
  (:action unlock_with_code
    :parameters (?l - code_lock)
    :precondition (known_code ?l)
    :effect (unlocked ?l)
  )

)
