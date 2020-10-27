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
  (define move-response-query (parse-json-state (read-json)))
  (define maybe-move (xtree-algorithm (make-game (first move-response-query))
                                      (second move-response-query)))
  (write-json (and maybe-move
                   (serialize-posns (list (move-from maybe-move)
                                          (move-to maybe-move))))))

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
  (define moves (for*/first ([posn target-posns]
                             [moves (in-values (filter (λ (move) (equal? (move-to move) move)
                                                         possible-moves)))]
                             #:when (not (empty? moves)))
                  (foldr tiebreaker (first moves) moves)))

  (foldr (λ (move maybe-best)
           (if maybe-best
               ...
               move)
           #f
           moves)
         )

  (foldl (λ (posn maybe-best)
           (foldr tiebreaker 

           )
         #f
         target-posns)

  )

;; tiebreaker : move? move? -> move?
;;
(define (tiebreaker move1 move2)
  (cond [(< (posn-y (move-from move1)) (posn-y (move-from move2))) move1]
        [(> (posn-y (move-from move1)) (posn-y (move-from move2))) move2]
        [(< (posn-x (move-from move1)) (posn-x (move-from move2))) move1]
        [(> (posn-x (move-from move1)) (posn-x (move-from move2))) move2])) 

(module+ test
  (require lang/posn
           rackunit
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

  )
  
  

