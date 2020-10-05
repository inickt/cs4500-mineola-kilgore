#lang racket/base

(require "tile.rkt")

;; make-random-board: natural? natural? (listof posn?) ??? -> board?
#;
(define (make-random-board width height holes ...)
  ...)

;; make-even-board: natural? natural? natural? ??? -> board?
#;
(define (make-even-board: width height fish ...)
  ...)

;; reachable-posns : board? posn? -> (listof posn?)
#;
(define (reachable-posns board current)
  ...)

;; remove-tile : board? tile? -> board?
#;
(define (remove-tile board tile)
  ...)
