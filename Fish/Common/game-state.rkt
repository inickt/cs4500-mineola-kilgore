#lang racket/base

(define-struct move [from to])
;; A Move is a (make-move posn? posn?)
;; and represents a penguin move on a fish board
