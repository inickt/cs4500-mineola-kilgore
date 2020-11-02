#lang racket/base

(require json
         lang/posn
         racket/list
         racket/promise
         "../../Fish/Common/board.rkt"
         "../../Fish/Common/json.rkt"
         "../../Fish/Common/game-tree.rkt"
         "../../Fish/Common/penguin-color.rkt"
         "../../Fish/Common/state.rkt"
         "../../Fish/Player/strategy.rkt")

(provide xtree)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xtree : -> void?
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
  (unless (is-move-valid? state move)
    (error "Move provided is invalid, should be valid"))
  (define moved-game (hash-ref (force (game-children (create-game state))) move))
  (and (not (end-game? moved-game))
       (penguin-color=? (player-color (state-current-player (game-state moved-game)))
                        (player-color (list-ref (state-players state)
                                                (modulo 1 (length (state-players state))))))
       (let ([potential-moves (hash-keys (force (game-children moved-game)))]
             [target-posns
              (map (λ (mover) (mover (move-to move)))
                   (list top-hexagon-posn
                         top-right-hexagon-posn
                         bottom-right-hexagon-posn
                         bottom-hexagon-posn
                         bottom-left-hexagon-posn
                         top-left-hexagon-posn))])
         (for*/first ([target-posn target-posns]
                      [found-move (in-value (find-best-move target-posn potential-moves))]
                      #:when found-move)
           found-move))))

;; find-best-move : posn? (list-of move?) -> (or/c false? move?)
;; Finds the best move to a given position in a list of moves using a tiebreaker if multiple are found
(define (find-best-move target-posn potential-moves)
  (for/foldr ([best-move #f])
    ([move (filter (λ (move) (equal? (move-to move) target-posn)) potential-moves)])
    (if (or (not best-move) (tiebreaker move best-move)) move best-move)))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require lang/posn
           rackunit
           "../../Fish/Other/util.rkt")

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
  ;; next can't move
  (check-false (xtree-algorithm (make-state '((3 0 0 2 2) (1 0 2 3 1))
                                            (list (make-player RED 3 (list (make-posn 1 3)))
                                                  (make-player BLACK 6 (list (make-posn 0 0)))
                                                  (make-player WHITE 4 (list (make-posn 1 4)))))
                                (make-move (make-posn 1 3) (make-posn 1 2))))
  ;; one player - weird edge case, moves to spot next to itself
  (check-equal? (xtree-algorithm (make-state '((1 1 0 1 1) (1 1 1 1 1))
                                             (list (make-player BLACK 0 (list (make-posn 0 0)))))
                                 (make-move (make-posn 0 0 ) (make-posn 1 2)))
                (make-move (make-posn 1 2) (make-posn 1 0)))
  ;; end game - cant move after
  (check-false (xtree-algorithm (make-state '((1 1 0 0 1) (0 1 0 0 1))
                                            (list (make-player BLACK 0 (list (make-posn 0 0)))
                                                  (make-player RED 0 (list (make-posn 0 4)))
                                                  (make-player WHITE 0 (list (make-posn 1 4)))))
                                (make-move (make-posn 0 0) (make-posn 0 1))))

  ;; +--- find-best-move ---+
  (check-false (find-best-move (make-posn 0 0) '()))
  (check-equal? (find-best-move (make-posn 1 1) (list (make-move (make-posn 0 0) (make-posn 1 0))
                                                      (make-move (make-posn 0 0) (make-posn 1 1))))
                (make-move (make-posn 0 0) (make-posn 1 1)))
  (check-equal? (find-best-move (make-posn 1 1) (list (make-move (make-posn 2 3) (make-posn 1 1))
                                                      (make-move (make-posn 0 0) (make-posn 1 0))
                                                      (make-move (make-posn 0 1) (make-posn 1 1))))
                (make-move (make-posn 0 1) (make-posn 1 1)))

  ;; Integration tests
  (check-integration xtree "../Tests/1-in.json" "../Tests/1-out.json")
  (check-integration xtree "../Tests/2-in.json" "../Tests/2-out.json")
  (check-integration xtree "../Tests/3-in.json" "../Tests/3-out.json")

  ;; Fest tests
  (check-fest xtree (build-path "./fest")))
