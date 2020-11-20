#lang racket/base

(require racket/class
         lang/posn
         "../Common/state.rkt"
         "../Common/player-interface.rkt"
         "../Player/player.rkt")

;; Provide players that fail for a variety of reasons, for testing use

(provide bad-player-error% bad-player-timeout% bad-player-garbage% bad-player-end%)

;; Player that throws errors
(define bad-player-error%
  (class* object% (player-interface)
    (super-new)
    (define/public (tournament-started num-players) (error "fail"))
    (define/public (tournament-ended did-win) (error "fail"))
    (define/public (initialize board num-players color) (error "fail"))
    (define/public (get-placement state) (error "fail"))
    (define/public (get-move state) (error "fail"))
    (define/public (terminate) (error "fail"))
    (define/public (finalize state) (error "fail"))))

;; Player that timesout when moving
(define bad-player-timeout%
  (class* object% (player-interface)
    (super-new)
    (define/public (tournament-started num-players) (tournament-started num-players))
    (define/public (tournament-ended did-win) (tournament-ended did-win))
    (define/public (initialize board num-players color) (initialize board num-players color))
    (define/public (get-placement state) (get-placement state))
    (define/public (get-move state) (get-move game))
    (define/public (terminate) (terminate))
    (define/public (finalize state) (finalize end-game))))
  
;; Player that gives garbage moves
(define bad-player-garbage%
  (class* object% (player-interface)
    (super-new)
    (define/public (tournament-started num-players) (void))
    (define/public (tournament-ended did-win) (void))
    (define/public (initialize board num-players color) (void))
    (define/public (get-placement state) (make-posn 0 0))
    (define/public (get-move state) (make-move (make-posn 0 0) (make-posn 0 1)))
    (define/public (terminate) (void))
    (define/public (finalize state) (void))))

;; Player that throws an error on tournaments ending
(define bad-player-end%
  (class player%
    (init [depth 2])
    (super-new [depth depth])
    (define/override (tournament-ended did-win)
      (error "I do not want to win"))))
