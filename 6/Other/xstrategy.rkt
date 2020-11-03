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

(provide xstrategy)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xstrategy : -> void?
;; Read a JSON Depth-State from STDIN, and finds the best move (if possible), written to STDOUT
(define (xstrategy)
  (define depth-state (parse-json-depth-state (read-json)))
  (define maybe-move (xstrategy-helper (second depth-state) (first depth-state)))
  (write-json (and maybe-move (serialize-posns (list (move-from maybe-move) (move-to maybe-move)))))
  (newline))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS

;; xstrategy-helper : state? (integer-in 1 2) -> (or/c false? move?)
;; Find the next best move for the given state's first player, searching up to the specified depth
(define (xstrategy-helper state depth)
  (define initial-game (create-game state))
  (and (not (end-game? initial-game))
       (penguin-color=? (player-color (state-current-player (game-state initial-game)))
                        (player-color (state-current-player state)))
       (get-move initial-game depth)))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require lang/posn
           rackunit
           "../../Fish/Other/util.rkt")

  ;; +--- xstrategy-helper ---+
  ;; no moves at all
  (check-false (xstrategy-helper (make-state '((0 0 1) (1 0 0))
                                             (list (make-player RED 2 (list (make-posn 0 2)))
                                                   (make-player WHITE 2 (list (make-posn 1 0)))))
                                 1))
  ;; no moves for current player
  (check-false (xstrategy-helper (make-state '((0 0 1) (1 2 0))
                                             (list (make-player RED 2 (list (make-posn 0 2)))
                                                   (make-player WHITE 2 (list (make-posn 1 0)))))
                                 2))
  ;; one move left
  (check-equal? (xstrategy-helper (make-state '((0 0 1) (1 2 0))
                                              (list (make-player WHITE 2 (list (make-posn 1 0)))
                                                    (make-player RED 2 (list (make-posn 0 2)))))
                                  2)
                (make-move (make-posn 1 0) (make-posn 1 1)))
  ;; complex game
  (check-equal? (xstrategy-helper (make-state '((1 2 3 0 3 1)
                                                (2 0 4 3 1 3)
                                                (1 4 3 1 2 0))
                                              (list (make-player BLACK 0 (list (make-posn 0 0)))
                                                    (make-player WHITE 0 (list (make-posn 2 4)))
                                                    (make-player RED 0 (list (make-posn 1 5))))) 2)
                (make-move (make-posn 0 0) (make-posn 1 2)))

  ;; Integration tests
  (check-integration xstrategy "../Tests/1-in.json" "../Tests/1-out.json")
  (check-integration xstrategy "../Tests/2-in.json" "../Tests/2-out.json")
  (check-integration xstrategy "../Tests/3-in.json" "../Tests/3-out.json")
  (check-integration xstrategy "../Tests/4-in.json" "../Tests/4-out.json")
  #;(check-integration xstrategy "../Tests/5-in.json" "../Tests/5-out.json"))
