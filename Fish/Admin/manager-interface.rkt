#lang racket/base

(require racket/class
         "../Common/player-interface.rkt"
         "referee.rkt")

(provide player-interface)


;; run-tournament : (non-empty-listof players/ages) observers -> ranking 

(list/c (is-a?/c player-interface) positive?) (listof tournament-observer?) ->

(define manager-interface
  (interface ()

  [run-tournament (-> (list/c (is-a?/c player-interface) positive?)
                      (listof tournament-observer?)
                      (list/c (is-a?/c player-interface) positive?))]))
