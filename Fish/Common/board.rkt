#lang racket/base

(require "tile.rkt"
         racket/contract
         lang/posn)

;; A Board is a (vectorof (vectorof tile?)) and uses a doubled coordinate system to represent a grid
;; of tesselated hexagons. The coordinates for a Board following format:
#|
(0,0)     (2,0)     (4,0) ... (n,0)
     (1,1)     (3,1)      
(0,2)     (2,2)     (4,2)     (n,2)
     (1,3)     (3,3)
(0,4)     (2,4)     (4,4)     (n,4)
...                            ...
(0,m)     (2,m)     (4,m) ... (n,m)
|#

;; make-random-board: natural? natural? (listof posn?) ??? -> board?
#;
(define (make-random-board width height holes ...)
  ...)

;; make-even-board: natural? natural? tile? -> board?
(define (make-even-board width height tile)
  (build-vector width (λ (x) (make-vector height tile))))

;; reachable-posns : board? posn? -> (listof posn?)
#;
(define (reachable-posns board current)
  ...)

;; remove-tile : board? posn? -> board?
(define (remove-tile board posn)
  (vector-set! (vector-ref board (posn-x posn))
               (posn-y posn)
               0)
  board)