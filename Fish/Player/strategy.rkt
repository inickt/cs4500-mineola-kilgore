#lang racket/base

(require racket/contract
         racket/list
         racket/math
         lang/posn
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/state.rkt"
         "../Common/penguin-color.rkt")

(provide (contract-out [get-placement (-> state? posn?)])
         (contract-out [get-move (-> game? natural? move?)])
         (contract-out [tiebreaker (-> move? move? boolean?)]))

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

;; get-move : game? natural? -> move?
;; Applies the maximin algorithm to determine the best move for the current player, searching up to
;; depth turns for the current player
(define (get-move game depth)
  (first (maximin-search game depth (player-color (state-current-player (game-state game))))))

;; tiebreaker : move? move? -> boolean?
;; Given two distinct moves, should the first be picked over the second in a tie?
;; Determined by topmost row, then leftmost column for both the from and to positions in the move.
(define (tiebreaker move1 move2)
  (or (< (posn-y (move-from move1)) (posn-y (move-from move2)))
      (< (posn-x (move-from move1)) (posn-x (move-from move2)))
      (< (posn-y (move-to move1)) (posn-y (move-to move2)))
      (< (posn-x (move-to move1)) (posn-x (move-to move2)))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPERS

;; maximin-search : game? posint? penguin-color? -> (list/c move (hash-of penguin-color? natural?))
;; Determines the best move, and the scores resulting from that move, based on a maximin algorithm
(define (maximin-search game remaining-depth original-player)
  (define color (player-color (state-current-player (game-state game))))
  (define new-depth (if (penguin-color=? color original-player)
                        (sub1 remaining-depth)
                        remaining-depth))
  (define mapped-children
    (apply-to-all-children game (λ (child) (maximin-recur child new-depth original-player))))
  (for/foldr ([maybe-best #f])
    ([(move score-map) (in-hash mapped-children)])
    
    (cond [(not maybe-best) (list move score-map)]
          [(> (hash-ref score-map color) (hash-ref (second maybe-best) color))
           (list move score-map)]
          [(< (hash-ref score-map color) (hash-ref (second maybe-best) color))
           maybe-best]
          [else (if (tiebreaker move (first maybe-best))
                    (list move score-map)
                    maybe-best)])))

;; maximin-recur : game-tree? natural? penguin-color? -> (hash-of penguin-color? natural?)
;; Applies the heuristic if the game is over or the depth has been reached, otherwise applies maximin
(define (maximin-recur game remaining-depth original-player)
  (if (or (end-game? game)
          (zero? remaining-depth))
      (fish-heuristic game)
      (second (maximin-search game remaining-depth original-player))))

;; fish-heuristic : game-tree? -> (hash-of penguin-color? natural?)
;; A mapping of each player's score in the game
(define (fish-heuristic game-tree)
  (define players (state-players (if (end-game? game-tree)
                                     (end-game-state game-tree)
                                     (finalize-state (game-state game-tree)))))
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
  
  ;; +--- get-move ---+
  (check-equal? (get-move test-game-1 1) (make-move (make-posn 1 2) (make-posn 1 1)))
  (check-equal? (get-move test-game-1 2) (make-move (make-posn 1 2) (make-posn 0 1)))
  (check-equal? (get-move test-game-2 1) (make-move (make-posn 0 0) (make-posn 1 2)))
  (check-equal? (get-move test-game-2 2) (make-move (make-posn 0 0) (make-posn 1 3)))
  (check-equal? (get-move test-game-2 3) (make-move (make-posn 0 0) (make-posn 1 2)))
  (check-equal? (get-move test-game-2 4) (make-move (make-posn 0 0) (make-posn 1 3)))
  (check-equal? (get-move test-game-2 10) (make-move (make-posn 0 0) (make-posn 1 3)))

  ;; +--- tiebreaker ---+
  ;; top most from
  (check-true (tiebreaker (make-move (make-posn 3 2) (make-posn 0 0))
                          (make-move (make-posn 3 3) (make-posn 0 0))))
  (check-false (tiebreaker (make-move (make-posn 3 3) (make-posn 0 0))
                           (make-move (make-posn 3 2) (make-posn 0 0))))
  ;; left most from
  (check-true (tiebreaker (make-move (make-posn 2 3) (make-posn 0 0))
                          (make-move (make-posn 3 3) (make-posn 0 0))))
  (check-false (tiebreaker (make-move (make-posn 3 3) (make-posn 0 0))
                           (make-move (make-posn 2 3) (make-posn 0 0))))
  ;; top most to
  (check-true (tiebreaker (make-move (make-posn 3 3) (make-posn 0 0))
                          (make-move (make-posn 3 3) (make-posn 0 1))))
  (check-false (tiebreaker (make-move (make-posn 3 3) (make-posn 0 1))
                           (make-move (make-posn 3 3) (make-posn 0 0))))
  ;; left most to
  (check-true (tiebreaker (make-move (make-posn 3 3) (make-posn 0 0))
                          (make-move (make-posn 3 3) (make-posn 1 0))))
  (check-false (tiebreaker (make-move (make-posn 3 3) (make-posn 1 3))
                           (make-move (make-posn 3 3) (make-posn 0 3))))
  ;; equal
  (check-false (tiebreaker (make-move (make-posn 3 3) (make-posn 0 0))
                           (make-move (make-posn 3 3) (make-posn 0 0))))

  ;; Internal Helper Functions
  ;; +--- maximin-search ---+
  ;; Game 1 partial searches
  (check-equal? (maximin-search test-game-1 1 WHITE)
                (list (make-move (make-posn 1 2) (make-posn 1 1)) (hash WHITE 6 BLACK 1)))
  ;; Game 1 complete searches
  (check-equal? (maximin-search test-game-1 2 WHITE)
                (list (make-move (make-posn 1 2) (make-posn 0 1)) (hash WHITE 7 BLACK 1)))
  (check-equal? (maximin-search test-game-1 3 WHITE)
                (list (make-move (make-posn 1 2) (make-posn 0 1)) (hash WHITE 7 BLACK 1)))
  ;; Game 2 partial searches
  (check-equal? (maximin-search test-game-2 1 BLACK)
                (list (make-move (make-posn 0 0) (make-posn 1 2)) (hash BLACK 5 RED 3 WHITE 2)))
  (check-equal? (maximin-search test-game-2 2 BLACK)
                (list (make-move (make-posn 0 0) (make-posn 1 3)) (hash BLACK 8 RED 4 WHITE 5)))
  (check-equal? (maximin-search test-game-2 3 BLACK)
                (list (make-move (make-posn 0 0) (make-posn 1 2)) (hash BLACK 10 RED 5 WHITE 9)))
  (check-equal? (maximin-search test-game-2 4 BLACK)
                (list (make-move (make-posn 0 0) (make-posn 1 3)) (hash BLACK 13 RED 8 WHITE 10)))
  ;; Game 2 complete searches
  (check-equal? (maximin-search test-game-2 5 BLACK)
                (list (make-move (make-posn 0 0) (make-posn 1 3)) (hash BLACK 15 RED 8 WHITE 11)))
  (check-equal? (maximin-search test-game-2 6 BLACK)
                (list (make-move (make-posn 0 0) (make-posn 1 3)) (hash BLACK 15 RED 8 WHITE 11)))
  ;; +--- maximin-recur ---+
  ;; Game 1 partial searches
  (check-equal? (maximin-recur test-game-1 0 WHITE)
                (hash BLACK 1 WHITE 2))
  (check-equal? (maximin-recur test-game-1 1 WHITE)
                (hash BLACK 1 WHITE 6))
  ;; Game 1 complete searches
  (check-equal? (maximin-recur test-game-1 2 WHITE)
                (hash BLACK 1 WHITE 7))
  (check-equal? (maximin-recur test-game-1 3 WHITE)
                (hash BLACK 1 WHITE 7))
  ;; Game 2 partial searches
  (check-equal? (maximin-recur test-game-2 0 BLACK)
                (hash BLACK 1 RED 3 WHITE 2))
  (check-equal? (maximin-recur test-game-2 1 BLACK)
                (hash BLACK 5 RED 3 WHITE 2))
  (check-equal? (maximin-recur test-game-2 2 BLACK)
                (hash BLACK 8 RED 4 WHITE 5))
  (check-equal? (maximin-recur test-game-2 3 BLACK)
                (hash BLACK 10 RED 5 WHITE 9))
  (check-equal? (maximin-recur test-game-2 4 BLACK)
                (hash BLACK 13 RED 8 WHITE 10))
  ;; Game 2 complete searches
  (check-equal? (maximin-recur test-game-2 5 BLACK)
                (hash BLACK 15 RED 8 WHITE 11))
  (check-equal? (maximin-recur test-game-2 6 BLACK)
                (hash BLACK 15 RED 8 WHITE 11))
  ;; +--- fish-heuristic ---+
  (check-equal? (fish-heuristic test-game-1)
                (hash BLACK 1 WHITE 2))
  (check-equal? (fish-heuristic test-game-2)
                (hash BLACK 1 RED 3 WHITE 2))
  (check-equal? (fish-heuristic
                 (create-game (make-state '((2))
                                          (list (make-player WHITE 10 (list (make-posn 0 0)))))))
                (hash WHITE 12)))
