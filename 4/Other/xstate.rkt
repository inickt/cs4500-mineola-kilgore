#lang racket/base

(require "../../Fish/Common/state.rkt"
         "../../Fish/Common/json.rkt")

(provide xstate)

;; silly-algorithm-desired-moves : posn? -> [listof posn?]
;; Builds an ordered list of the algorithm's desired TO posns
(define (silly-algorithm-desired-moves posn)
  (define x (posn-x posn))
  (define y (posn-y posn))
  
  (define n  (make-posn (- 2 x)  y))
  (define ne (make-posn (+ 1 x) (- 1 y)))
  (define se (make-posn (+ 1 x) (+ 1 y)))
  (define s  (make-posn x       (+ 2 y)))
  (define sw (make-posn (- 1 x) (+ 1 y)))
  (define nw (make-posn (- 1 x) (- 1 y)))
  
  (list n ne se s sw nw))

;; apply-algorithm : [listof posn?] state -> state?
;; attempts to make the list of moves in order, or #false if all fail
(define (apply-algorithm cur-posn algo-moves state)
  (with-handlers ([exn:fail? (λ (e) (displayln e))])
    (cond [(empty? algo-moves) #f]
          [else  (move-penguin (player-color (first (state-players state)))
                               cur-posn
                               (first algo-moves)
                               state)])))

(define (xstate)
  (displayln "Hello world"))