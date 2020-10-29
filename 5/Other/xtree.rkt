#lang racket/base

(require json
         lang/posn
         racket/list
         racket/promise
         "../../Fish/Common/board.rkt"
         "../../Fish/Common/json.rkt"
         "../../Fish/Common/game-tree.rkt"
         "../../Fish/Common/state.rkt"
         "../../Fish/Player/strategy.rkt")

(provide xtree)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xtree: -> void?
;; Read a Move-Response-Query from STDIN, applies the move to the state, finds the best move
;; (according to xtree-algorithm, if possible), writes to STDOUT.
(define (xtree)
  (define move-response-query (parse-json-move-response-query (read-json)))
  (define maybe-move (xtree-algorithm (first move-response-query) (second move-response-query)))
  (write-json (and maybe-move (serialize-posns (list (move-from maybe-move) (move-to maybe-move)))))
  (newline))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS

;; xtree-algorithm : state? move? -> (or/c false? move?)
;; Takes a state, applies a valid move, and finds the first potential move that the next player
;; can take to be next to the first player's move (in clockwise order).
(define (xtree-algorithm state move)
  ;; TODO state refactor will change this call
  (unless (is-move-valid? (player-color (first (state-players state)))
                          (move-from move)
                          (move-to move)
                          state)
    (error "Move provided is invalid, should be valid"))
  (define moved-game (hash-ref (force (game-children (create-game state))) move))
  
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
                        (if (or (not maybe-move) (tiebreaker move maybe-move))
                            move
                            maybe-move))
                      #f
                      (filter (λ (move) (equal? (move-to move) posn))
                              (hash-keys (force (game-children moved-game)))))))
         #f
         target-posns))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require lang/posn
           rackunit
           "../../Fish/Other/util.rkt"
           "../../Fish/Common/penguin-color.rkt")

  ;; +--- xtree-algorithm ---+
  ;; impossible to move
  (check-false (xtree-algorithm
                (make-state '((1 1 1 0 1) (1 1 1 1 1))
                            (list (make-player BLACK 0 (list (make-posn 0 0)))
                                  (make-player RED 0 (list (make-posn 0 4)))))
                (make-move (make-posn 0 0) (make-posn 1 2))))
  ;; move to NE chosen over SE, S, and SW
  (check-equal? (xtree-algorithm
                 (make-state '((1 1 1 1 1) (1 1 1 1 1))
                             (list (make-player BLACK 0 (list (make-posn 0 0)))
                                   (make-player RED 0 (list (make-posn 1 4)))))
                 (make-move (make-posn 0 0) (make-posn 0 1)))
                (make-move (make-posn 1 4) (make-posn 1 0)))
  ;; multiple penguins with tiebreaker
  (check-equal? (xtree-algorithm
                 (make-state '((1 1 1 1) (1 1 1 1))
                             (list (make-player BLACK 0 (list (make-posn 0 2)
                                                               (make-posn 1 3)))
                                   (make-player RED 0 (list (make-posn 1 1)
                                                             (make-posn 1 0)))))
                 (make-move (make-posn 0 2) (make-posn 0 1)))
                (make-move (make-posn 1 0) (make-posn 1 2)))

  ;; Integration tests
  (check-integration xtree "../Tests/1-in.json" "../Tests/1-out.json")
  (check-integration xtree "../Tests/2-in.json" "../Tests/2-out.json")
  (check-integration xtree "../Tests/3-in.json" "../Tests/3-out.json"))
