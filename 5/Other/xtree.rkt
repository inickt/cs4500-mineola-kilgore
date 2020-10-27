#lang racket/base

(require lang/posn
         json
         racket/list
         "../../Fish/Common/board.rkt"
         "../../Fish/Common/json.rkt"
         "../../Fish/Common/game-tree.rkt"
         "../../Fish/Common/state.rkt")

(provide xtree)

(define (xtree)
  (define move-response-query (parse-move-response-query (read-json)))
  (define maybe-move (xtree-algorithm (create-game (first move-response-query))
                                      (second move-response-query)))
  (write-json (and maybe-move
                   (serialize-posns (list (move-from maybe-move)
                                          (move-to maybe-move)))))
  (newline))

;; xtree-algorithm : game? move? -> (or/c false? move?)
;; Takes a game, applies a valid move, and finds the first potential move that the next player
;; can take to be next to the first player's move (in clockwise order).
(define (xtree-algorithm game move)
  (unless (is-valid-move? game move)
    (error "Move provided is invalid, should be valid"))
  (define moved-game (apply-move game move))
  (define possible-moves (hash-keys (all-possible-moves moved-game)))
  (define target-posns
    (map (λ (mover) (mover (move-to move)))
         (list top-hexagon-posn
               top-right-hexagon-posn
               bottom-right-hexagon-posn
               bottom-hexagon-posn
               bottom-left-hexagon-posn
               top-left-hexagon-posn)))
  (foldl (λ (posn maybe-best)
           (or maybe-best
               (foldr (λ (move maybe-move)
                        (if maybe-move
                            (tiebreaker move maybe-move)
                            move))
                      #f
                      (filter (λ (move) (equal? (move-to move) posn)) possible-moves))))
         #f
         target-posns))

;; tiebreaker : move? move? -> move?
;; Given two distinct moves, determines which should be prioritized
(define (tiebreaker move1 move2)
  (cond [(< (posn-y (move-from move1)) (posn-y (move-from move2))) move1]
        [(> (posn-y (move-from move1)) (posn-y (move-from move2))) move2]
        [(< (posn-x (move-from move1)) (posn-x (move-from move2))) move1]
        [(> (posn-x (move-from move1)) (posn-x (move-from move2))) move2])) 

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require lang/posn
           rackunit
           "../../Fish/Other/util.rkt"
           "../../Fish/Common/penguin-color.rkt")

  ;; +--- xtree-algorithm ---+
  ;; impossible to move
  (check-equal? (xtree-algorithm
                 (make-game (make-state '((1 1 1 0 1) (1 1 1 1 1))
                                        (list (make-player BLACK 0 (list (make-posn 0 0)))
                                              (make-player RED 0 (list (make-posn 0 4)))))
                            BLACK
                            '())
                 (make-move (make-posn 0 0) (make-posn 1 2)))
                #f)

  ;; move to south east over south
  (check-equal? (xtree-algorithm
                 (make-game (make-state '((1 1 1 1 1) (1 1 1 1 1))
                                        (list (make-player BLACK 0 (list (make-posn 0 0)))
                                              (make-player RED 0 (list (make-posn 1 4)))))
                            BLACK
                            '())
                 (make-move (make-posn 0 0) (make-posn 0 1)))
                (make-move (make-posn 1 4) (make-posn 1 0)))

  ;; multiple penguins TODO


  ;; Integration tests
  (check-integration xtree "../Tests/1-in.json" "../Tests/1-out.json")
  (check-integration xtree "../Tests/2-in.json" "../Tests/2-out.json")
  (check-integration xtree "../Tests/3-in.json" "../Tests/3-out.json"))
  
  

