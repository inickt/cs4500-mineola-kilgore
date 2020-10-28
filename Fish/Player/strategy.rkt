#lang racket/base

(require racket/list
         lang/posn
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/state.rkt"
         "../Common/penguin-color.rkt")

#;(provide ...)

; Programming Task For this assignment, you are to implement a strategy component that takes care of
; two decisions:

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


;; determine-move : game? natural? -> move?
;; Applies the maximin algorithm to determine the best move for the current player, searching up to
;; depth turns for the current player
(define (fish-maximin game depth)
  (first (maximin-search game depth (game-player-turn game))))

;; maximin-search : game? posint? penguin-color? -> (list/c move (hash-of penguin-color? natural?))
;; Determines the best move, and the scores resulting from that move, based on a maximin algorithm
(define (maximin-search game remaining-depth original-player)
  (define color (game-player-turn game))
  (define new-depth (if (penguin-color=? (game-player-turn game) original-player)
                        (sub1 remaining-depth)
                        remaining-depth))
  (define mapped-children
    (apply-to-all-children game (λ (child) (maximin-h child new-depth original-player))))
  
  (for/foldr ([maybe-best #f])
    ([(move score-map) (in-hash mapped-children)])
    (cond[(not maybe-best) (list move score-map)]
         [(> (hash-ref score-map color) (hash-ref (second maybe-best) color))
          (list move score-map)]
         [(< (hash-ref score-map color) (hash-ref (second maybe-best) color))
          maybe-best]
         [else (if (tiebreaker move (first maybe-best))
                   (list move score-map)
                   maybe-best)])))

;; maximin-h : game-tree? natural? penguin-color? -> (hash-of penguin-color? natural?)
;; Applies the heuristic if the game is over or the depth has been reached, otherwise applies maximin
(define (maximin-h game remaining-depth original-player)
  (if (or (end-game? game)
          (zero? remaining-depth))
      (fish-heuristic game)
      (second (maximin-search game remaining-depth original-player))))

;; tiebreaker : move? move? -> boolean?
;; Given two distinct moves, determines which should be prioritized based on topmost row first, then
;; leftmost column
(define (tiebreaker move1 move2)
  (or (< (posn-y (move-from move1)) (posn-y (move-from move2)))
      (< (posn-x (move-from move1)) (posn-x (move-from move2)))
      (< (posn-y (move-to move1)) (posn-y (move-to move2)))
      (< (posn-x (move-to move1)) (posn-x (move-to move2)))))

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

  (define test-game-1
    (create-game (make-state '((1 2 0 3) (0 4 2 0))
                             (list (make-player WHITE 0 (list (make-posn 1 2)))
                                   (make-player BLACK 0 (list (make-posn 0 0)))))))
  (define test-game-2
    (create-game (make-state '((1 2 3 0 3 1)
                               (2 0 4 3 1 3)
                               (1 4 3 1 2 0))
                             (list (make-player BLACK 0 (list (make-posn 0 0)))
                                   (make-player WHITE 0 (list (make-posn 2 4)))
                                   (make-player RED 0 (list (make-posn 1 5)))))))
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
