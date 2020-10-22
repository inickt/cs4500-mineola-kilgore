#lang racket/base

(require racket/contract
         "state.rkt")

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct move [from to])
;; A Move is a (make-move posn? posn?)
;; and represents a penguin move on a fish board

(define-struct game [state player-turn kicked] #:transparent)
;; (make-game state? penguin? (listof? penguin?))
;; TODO

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : state? -> game?

;; is-valid-move? : game? move? -> boolean?

;; make-move : game? move? -> game?

;; all-possible-moves : game? -> (hash/c move? game?)

;; next turn : game? -> penguin?
;; keeps in mind kicked
