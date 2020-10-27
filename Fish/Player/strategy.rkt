#lang racket/base

(require racket/list
         lang/posn
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/state.rkt")

#;(provide ...)

; Programming Task For this assignment, you are to implement a strategy component that takes care of
; two decisions:

; penguin placements
; It places a penguin in the next available free spot followning a zig zag pattern that starts at the
; top left corner. That is, the search goes from left to right in each row and moves down to the next
; row when one is filled up.
; This piece of functionality may assume that the referee will set up a game board that is large
; enough to accommodate all the penguins of all the players.

; a choice of action for the player whose turn it is
; It picks the action that realizes the minimal maximum gain after looking ahead N > 0 turns for this
; player in the game tree for the current state.
; The minimal maximum gain after N turns is the highest score a player can make after playing the
; specified number of turns—assuming that all opponents pick one of the moves that minimizes the
; player’s gain.

; Tie Breaker If several different actions can realize the same gain, the strategy moves the penguin
; that has the lowest row number for the place from which the penguin is moved and, within this row,
; the lowest column number. In case this still leaves the algorithm with more than one choice, the
; process is repeated for the target field to which the penguins will move. Why is this process
; guaranteed to stop with a single action?

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; get-placement : state? -> posn?
;; Determines the next desired placement for a penguin of the given color
;; NOTE: The passed state must have a legal tile for the penguin to be placed on.
(define (get-placement state)
  (define board (state-board state))
  (define width (length board))
  (define height (length (first board)))
  (for*/first ([col height]
               [row width]
               [placement (in-value (make-posn row col))]
               #:when (and (not (member placement (append-map player-places (state-players state))))
                           (valid-tile? placement board)))
    placement))

;; fish-minimax-search : game-tree? natural? -> (hash-of move? (hash-of penguin-color? natural?))
;; Determines the best move based on a naive minimax algorithm

;; TODO fix recursion here
(define (fish-minimax-search game-tree remaining-depth)
  (if (or (zero? remaining-depth)
          (end-game? game-tree)
          (not (can-color-move? (game-player-turn game-tree) (game-state game-tree))))
      (fish-heuristic game-tree)
      (apply-to-all-children
       game-tree
       (λ (child)
         (fish-minimax-search child (sub1 remaining-depth))))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPERS

;; fish-heuristic : game-tree? -> (hash-of penguin-color? natural?)
;; A mapping of each player's score in the game
(define (fish-heuristic game-tree)
  (define players (state-players (if (end-game? game-tree)
                                     (end-game-state game-tree)
                                     (game-state game-tree))))
  (for/hash ([player players])
    (values (player-color player) (player-score player))))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require rackunit
           "../Common/penguin-color.rkt")
  ;; Provided
  ;; +--- get-placement ---+
  ;; Base case
  (check-equal? (get-placement (make-state '((1)) (list (make-player RED 0 '()))))
                (make-posn 0 0))
  ;; Move past holes and existing penguins
  (check-equal? (get-placement (make-state '((1 1 1) (1 1 1) (0 1 1) (1 1 1))
                                           (list (make-player RED 0 (list (make-posn 0 0)))
                                                 (make-player BLACK 0 (list (make-posn 1 0))))))
                (make-posn 3 0))
  ;; Place on 2nd line
  (check-equal?
   (get-placement (make-state '((1 1 1) (1 1 1) (0 1 1) (1 1 1))
                              (list (make-player RED 0 (list (make-posn 0 0) (make-posn 0 1)))
                                    (make-player BLACK 0 (list (make-posn 1 0)))
                                    (make-player WHITE 0 (list (make-posn 3 0))))))
   (make-posn 1 1))
  ;; Place in the last available spot, ending the game
  (check-equal?
   (get-placement (make-state '((1 1) (1 0) (0 0) (1 1))
                              (list (make-player RED 0 (list (make-posn 0 0) (make-posn 0 1)))
                                    (make-player BLACK 0 (list (make-posn 1 0)))
                                    (make-player WHITE 0 (list (make-posn 3 0))))))
   (make-posn 3 1))
                              
  )
