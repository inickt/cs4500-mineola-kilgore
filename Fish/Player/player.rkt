#lang racket/base

(require racket/class
         "../Common/player-interface.rkt"
         (prefix-in strategy: "strategy.rkt"))

(provide player%)

;; +-------------------------------------------------------------------------------------------------+
;; CONSTANTS

(define DEFAULT-SEARCH-DEPTH 2)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

(define player%
  (class* object% (player-interface)
    (init [depth DEFAULT-SEARCH-DEPTH])
    (define search-depth depth)
    (super-new)
    (define/public (initialize board num-players color)
      (void))

    (define/public (get-placement state)
      (strategy:get-placement state))
    
    (define/public (get-move game)
      (strategy:get-move game search-depth))

    (define/public (terminate)
      (void))

    (define/public (finalize end-game)
      (void))))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require lang/posn
           rackunit
           "../Common/game-tree.rkt"
           "../Common/penguin-color.rkt"
           "../Common/state.rkt")

  (define player1 (new player% [depth 1]))
  (define player2 (new player% [depth 2]))

  (define test-state (make-state '((1 2 3) (1 2 0) (2 2 1))
                                 (list (make-player RED 0 (list (make-posn 0 0)))
                                       (make-player WHITE 0 (list (make-posn 2 0))))))
  
  (check-equal? (send player1 get-placement test-state)
                (make-posn 1 0))
  (check-equal? (send player2 get-placement
                      (make-state '((1 2 3) (0 2 0) (2 2 1))
                                  (list (make-player RED 0 (list (make-posn 0 0)))
                                        (make-player WHITE 0 (list (make-posn 2 0))))))
                (make-posn 0 1))
  (check-equal? (send player1 get-move (create-game test-state))
                (make-move (make-posn 0 0) (make-posn 0 1)))
  (check-equal? (send player2 get-move (create-game test-state))
                (make-move (make-posn 0 0) (make-posn 0 2))))
