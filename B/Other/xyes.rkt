#lang racket/base

(require racket/list
         racket/stream
         racket/string
         rackunit)

(provide xyes LIM COUNT MSG)

;+---------------------------------------------------------------------------------------------------+
(define LIM "-limit")
(define COUNT 20)
(define MSG "hello world")

;+---------------------------------------------------------------------------------------------------+
;; Formats the list of args as a single string
;; format-args: [Listof String] Bool -> String
(define (format-args args lim)
  (define loStr (if lim (rest args) args))
  (if (empty? loStr) MSG (string-join loStr " ")))

(check-equal? (format-args '() #f) MSG)
(check-equal? (format-args '("hello" "there") #f) "hello there")
(check-equal? (format-args '(LIM) #t) MSG)
(check-equal? (format-args '(LIM "hi" "hello") #t) "hi hello")

;; Creates a stream of the arg str 20 times or infinitely
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
(check-equal? (stream->list (stream-take (output-stream "1 2 3" #f) 100))
              (build-list 100 (λ (x) "1 2 3")))

;; Creates a stream of the args joined by a space 20 times or infinitely depending on
;; whether the '-limit' flag is supplied first
;; xyes: [Listof String] -> [Stream String]
(define (xyes args)
  (define limit (and (cons? args) (string=? (first args) LIM)))
  (output-stream (format-args args limit) limit))

(check-equal? (stream-first (xyes '()))
              MSG)
(check-equal? (stream->list (stream-take (xyes '()) 100))
              (build-list 100 (λ (x) MSG)))
(check-equal? (stream-first (xyes '("hi")))
              "hi")
(check-equal? (stream->list (stream-take (xyes '("hi")) 100))
              (build-list 100 (λ (x) "hi")))
(check-equal? (stream-first (xyes '("-limithello")))
              "-limithello")
(check-equal? (stream->list (stream-take (xyes '("-limithello")) 100))
              (build-list 100 (λ (x) "-limithello")))
(check-equal? (stream-first (xyes (list "hi" "hello" "1" LIM)))
              (string-append "hi hello 1 " LIM))
(check-equal? (stream->list (stream-take (xyes (list "hi" "hello" "1" LIM)) 100))
              (build-list 100 (λ (x) (string-append "hi hello 1 " LIM))))
(check-equal? (stream->list (xyes (list LIM)))
              (build-list COUNT (λ (x) MSG)))
(check-equal? (stream->list (xyes (list LIM "1 2 3")))
              (build-list COUNT (λ (x) "1 2 3")))
