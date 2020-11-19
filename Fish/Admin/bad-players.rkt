#lang racket/base

(require racket/class
         lang/posn
         "../Common/state.rkt"
         "../Common/player-interface.rkt")

;; Provide players that fail for a variety of reasons, for testing use

(provide bad-player-error% bad-player-timeout% bad-player-garbage%)

;; Player that throws errors
(define bad-player-error%
  (class* object% (player-interface)
    (super-new)
    (define/public (tournament-started num-players) (error "fail"))
    (define/public (tournament-ended did-win) (error "fail"))
    (define/public (initialize board num-players color) (error "fail"))
    (define/public (get-placement state) (error "fail"))
    (define/public (get-move game) (error "fail"))
    (define/public (terminate) (error "fail"))
    (define/public (finalize end-game) (error "fail"))))

;; Player that timesout when moving
(define bad-player-timeout%
  (class* object% (player-interface)
    (super-new)
    (define/public (tournament-started num-players) (tournament-started num-players))
    (define/public (tournament-ended did-win) (tournament-ended did-win))
    (define/public (initialize board num-players color) (initialize board num-players color))
    (define/public (get-placement state) (get-placement state))
    (define/public (get-move game) (get-move game))
    (define/public (terminate) (terminate))
    (define/public (finalize end-game) (finalize end-game))))
  
;; Player that gives garbage moves
(define bad-player-garbage%
  (class* object% (player-interface)
    (super-new)
    (define/public (tournament-started num-players) (void))
    (define/public (tournament-ended did-win) (void))
    (define/public (initialize board num-players color) (void))
    (define/public (get-placement state) (make-posn 0 0))
    (define/public (get-move game) (make-move (make-posn 0 0) (make-posn 0 1)))
    (define/public (terminate) (void))
    (define/public (finalize end-game) (void))))