#! /bin/sh
#|
  exec racket -u "$0" ${1+"$@"}
|#
#lang racket

(require rackunit)
(require racket/contract)

#|
1. parse the command line args
 1.1 find out if -limit is FIRST
 1.2 find out if there is a str to print or if we should print "hello world"
2. print in 20 or infinite loop
|#


;; LoS -> Void
(define (main loStr)
  (cond ([(empty? loStr) (output-args "hello world" #f)]
         [(string=? (first loStr) "-limit") (output-args (string-join (rest loStr) " ") #t)]
         [(output-args (string-join loStr " ") #f)])))

;; Prints the arg str 20 times or infinitely
;; Str Bool -> Void
(define (output-args argstr limit)
  (if limit
      (for ([i 20]) (displayln argstr))
      (print-infinitely argstr)))


;; Prints the given string infinitely
;; Cannot be tested... please don't make me try
;; Str -> Void
(define (print-infinitely argstr)
  (displayln argstr)
  (print-infinitely argstr))
