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
;; DESCRIPTION

;; No Data Definitions were required for this strategy component.
;; - The definition for a State and Move can be found in "Fish/Common/state.rkt"
;; - The definition for a GameTree, Game, and EndGame can be found in "Fish/Common/game-tree.rkt"

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
  (car (maximin-search game depth (player-color (state-current-player (game-state game))))))

;; tiebreaker : move? move? -> boolean?
;; Given two distinct moves, should the first be picked over the second in a tie?
;; Determined by topmost row, then leftmost column for both the from and to positions in the move.
(define (tiebreaker move1 move2)
  (define x1-from (posn-x (move-from move1)))
  (define y1-from (posn-y (move-from move1)))
  
  (define x1-to (posn-x (move-to move1)))
  (define y1-to (posn-y (move-to move1)))
  
  (define x2-from (posn-x (move-from move2)))
  (define y2-from (posn-y (move-from move2)))
  
  (define x2-to (posn-x (move-to move2)))
  (define y2-to (posn-y (move-to move2)))
  
  (cond [(not (= y1-to y2-to)) (< y1-to y2-to)]
        [(not (= x1-to x2-to)) (< x1-to x2-to)]
        [(not (= y1-from y2-from)) (< y1-from y2-from)]
        [(not (= x1-from x2-from)) (< x1-from x2-from)]
        [else #f]))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPERS

;; maximin-search : game? posint? penguin-color? -> (cons/c move? natural?)
;; Determines the best move, and the scores resulting from that move, based on a maximin algorithm
(define (maximin-search game remaining-depth original-player)
  (define color (player-color (state-current-player (game-state game))))
  (define maximizing-player? (penguin-color=? color original-player))
  (define new-depth (cond [(not (can-color-move? (game-state game) original-player)) 0]
                          [maximizing-player? (sub1 remaining-depth)]
                          [else remaining-depth]))

  (define maximizing-player-potential-scores
    (apply-to-all-children game (λ (child) (maximin-recur child new-depth original-player))))
  
  (for/foldr ([maybe-best #f])
    ([move-score-pair (in-hash-pairs maximizing-player-potential-scores)])
    (if (not maybe-best)
        move-score-pair
        (maximin-better-move move-score-pair maybe-best maximizing-player?))))

;; maximin-better-move :
;; (cons/c move? natural?) (cons/c move? natural?) boolean? -> (cons/c move? natural?)
;; Determines the higher score if maximizing, the lower score if not maximizing, else whichever
;; move is preferred by the tiebreaker algorithm
(define (maximin-better-move candidate previous maximizing?)
  (define candidate-preferred ((if maximizing? > <) (cdr candidate) (cdr previous)))
  (cond [(= (cdr candidate) (cdr previous))
         (if (tiebreaker (car candidate) (car previous))
                  candidate
                  previous)]
        [candidate-preferred candidate]
        [else previous]))

;; maximin-recur : game-tree? natural? penguin-color? -> natural?
;; Applies the heuristic if the game is over or the depth has been reached, otherwise applies maximin
(define (maximin-recur game remaining-depth original-player)
  (if (or (end-game? game) (zero? remaining-depth))
      (fish-heuristic game original-player)
      (cdr (maximin-search game remaining-depth original-player))))

;; fish-heuristic : game-tree? penguin-color? -> natural?
;; Gets the score of the maximizing player
(define (fish-heuristic game-tree maximizing-player)
  (player-score (findf (λ (player) (penguin-color=? (player-color player) maximizing-player))
                       (state-players (if (end-game? game-tree)
                                          (end-game-state game-tree)
                                          (game-state game-tree))))))

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
  (check-equal? (get-move test-game-1 1) (make-move (make-posn 1 2) (make-posn 0 1)))
  (check-equal? (get-move test-game-1 2) (make-move (make-posn 1 2) (make-posn 0 1)))
  (check-equal? (get-move test-game-2 1) (make-move (make-posn 0 0) (make-posn 0 1)))
  (check-equal? (get-move test-game-2 2) (make-move (make-posn 0 0) (make-posn 1 2)))
  (check-equal? (get-move test-game-2 3) (make-move (make-posn 0 0) (make-posn 1 3)))
  (check-equal? (get-move test-game-2 4) (make-move (make-posn 0 0) (make-posn 1 2)))
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
  ;; y1-to < y2-to but x1-to > x2-to
  (check-true (tiebreaker (make-move (make-posn 3 3) (make-posn 1 0))
                          (make-move (make-posn 3 3) (make-posn 0 1))))
  ;; y1-from < y2-from but x1-from > x2-from
  (check-true (tiebreaker (make-move (make-posn 1 0) (make-posn 0 0))
                          (make-move (make-posn 0 1) (make-posn 0 0))))
  ;; Internal Helper Functions
  ;; +--- maximin-search ---+
  ;; Game 1 partial searches
  (check-equal? (maximin-search test-game-1 1 WHITE)
                (cons (make-move (make-posn 1 2) (make-posn 0 1)) 2))
  ;; Game 1 complete searches
  (check-equal? (maximin-search test-game-1 2 WHITE)
                (cons (make-move (make-posn 1 2) (make-posn 0 1)) 4))
  (check-equal? (maximin-search test-game-1 3 WHITE)
                (cons (make-move (make-posn 1 2) (make-posn 0 1)) 4))
  ;; Game 2 partial searches
  (check-equal? (maximin-search test-game-2 1 BLACK)
                (cons (make-move (make-posn 0 0) (make-posn 0 1)) 1))
  (check-equal? (maximin-search test-game-2 2 BLACK)
                (cons (make-move (make-posn 0 0) (make-posn 1 2)) 5))
  (check-equal? (maximin-search test-game-2 3 BLACK)
                (cons (make-move (make-posn 0 0) (make-posn 1 3)) 8))
  (check-equal? (maximin-search test-game-2 4 BLACK)
                (cons (make-move (make-posn 0 0) (make-posn 1 2)) 10))
  ;; Game 2 complete searches
  (check-equal? (maximin-search test-game-2 5 BLACK)
                (cons (make-move (make-posn 0 0) (make-posn 1 3)) 13))
  (check-equal? (maximin-search test-game-2 6 BLACK)
                (cons (make-move (make-posn 0 0) (make-posn 1 3)) 13))
  ;; +--- maximin-better-move ---+
  (check-equal? (maximin-better-move (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0)
                                     (cons (make-move (make-posn 1 0) (make-posn 1 1)) 1)
                                     #t)
                (cons (make-move (make-posn 1 0) (make-posn 1 1)) 1))
  (check-equal? (maximin-better-move (cons (make-move (make-posn 1 0) (make-posn 1 1)) 1)
                                     (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0)
                                     #t)
                (cons (make-move (make-posn 1 0) (make-posn 1 1)) 1))
  (check-equal? (maximin-better-move (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0)
                                     (cons (make-move (make-posn 1 0) (make-posn 1 1)) 1)
                                     #f)
                (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0))
  (check-equal? (maximin-better-move (cons (make-move (make-posn 1 0) (make-posn 1 1)) 1)
                                     (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0)
                                     #f)
                (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0))
  (check-equal? (maximin-better-move (cons (make-move (make-posn 1 0) (make-posn 1 1)) 0)
                                     (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0)
                                     #t)
                (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0))
  (check-equal? (maximin-better-move (cons (make-move (make-posn 1 0) (make-posn 1 1)) 0)
                                     (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0)
                                     #f)
                (cons (make-move (make-posn 0 0) (make-posn 0 1)) 0))
  ;; +--- maximin-recur ---+
  ;; Game 1 partial searches
  (check-equal? (maximin-recur test-game-1 0 WHITE) 0)
  (check-equal? (maximin-recur test-game-1 1 WHITE) 2)
  ;; Game 1 complete searches
  (check-equal? (maximin-recur test-game-1 2 WHITE) 4)
  (check-equal? (maximin-recur test-game-1 3 WHITE) 4)
  ;; Game 2 partial searches
  (check-equal? (maximin-recur test-game-2 0 BLACK) 0)
  (check-equal? (maximin-recur test-game-2 1 BLACK) 1)
  (check-equal? (maximin-recur test-game-2 2 BLACK) 5)
  (check-equal? (maximin-recur test-game-2 3 BLACK) 8)
  (check-equal? (maximin-recur test-game-2 4 BLACK) 10)
  ;; Game 2 complete searches
  (check-equal? (maximin-recur test-game-2 5 BLACK) 13)
  (check-equal? (maximin-recur test-game-2 6 BLACK) 13)
  ;; +--- fish-heuristic ---+
  (check-equal? (fish-heuristic test-game-1 BLACK) 0)
  (check-equal? (fish-heuristic test-game-1 WHITE) 0)
  (check-equal? (fish-heuristic
                 (create-game (make-state
                               '((2 1))
                               (list (make-player WHITE 10 (list (make-posn 0 0))))))
                 WHITE)
                10)
  (check-equal? (fish-heuristic
                 (create-game (make-state
                               '((2))
                               (list (make-player WHITE 10 (list (make-posn 0 0))))))
                 WHITE)
                10))
