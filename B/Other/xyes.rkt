#lang racket/base

(require racket/list
         racket/stream
         racket/string
         rackunit)

;+---------------------------------------------------------------------------------------------------+
(provide xyes LIM COUNT MSG)

;+---------------------------------------------------------------------------------------------------+
(define LIM "-limit")
(define COUNT 20)
(define MSG "hello world")

;+---------------------------------------------------------------------------------------------------+
;; Formats the list of command line args as a single string
;; format-args: [Listof String] Bool -> String
(define (format-args args lim)
  (define loStr (if lim (rest args) args))
  (if (empty? loStr) MSG (string-join loStr " ")))

(check-equal? (format-args '() #f) "hello world")
(check-equal? (format-args '("hello") #f) "hello")
(check-equal? (format-args '(LIM) #t) "hello world")
(check-equal? (format-args '(LIM "hi") #t) "hi")

;; TODO Prints the arg str 20 times or infinitely
;; output-stream: String Bool -> [Stream String]
(define (output-stream argstr limit)
  (if limit
      (for/stream ([i COUNT]) argstr)
      (letrec ([infinite-stream (stream-cons argstr infinite-stream)])
        infinite-stream)))

(check-equal? (stream->list (output-stream MSG #t))
              (build-list COUNT (λ (x) MSG)))
(check-equal? (stream-first (output-stream "hi" #f))
              "hi")
(check-equal? (stream-ref (output-stream "1 2 3" #f) 100)
              "1 2 3")

;; Creates a stream of the args joined by a space 20 times or infinitely depending on
;; whether the '-limit' flag is supplied first
;; xyes: [Listof String] -> [Stream String]
(define (xyes args)
  (define limit (and (cons? args) (string=? (first args) LIM)))
  (output-stream (format-args args limit) limit))

(check-equal? (stream-first (xyes '()))
              MSG)
(check-equal? (stream-ref (xyes '()) 100)
              MSG)
(check-equal? (stream-first (xyes '("hi")))
              "hi")
(check-equal? (stream-ref (xyes '("hi")) 100)
              "hi")
(check-equal? (stream->list (xyes (list LIM)))
              (build-list COUNT (λ (x) MSG)))
(check-equal? (stream->list (xyes (list LIM "1 2 3")))
              (build-list COUNT (λ (x) "1 2 3")))
(check-equal? (stream-first (xyes (list "1 2 3" LIM)))
              (string-append "1 2 3" " " LIM))
(check-equal? (stream-ref (xyes (list "1 2 3" LIM)) 100)
              (string-append "1 2 3" " " LIM))
