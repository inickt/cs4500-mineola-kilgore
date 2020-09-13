#lang racket/base

(require racket/list
         racket/port
         racket/string
         racket/system
         rackunit
         "xyes.rkt")

;; xyes
;; test-xyes: [Listof String] -> [Listof String]
(define (test-xyes args)
  (string-split (with-output-to-string (λ () (xyes args))) "\n"))

(check-equal? (test-xyes (list LIM)) (build-list 20 (λ (x) "hello world")))
(check-equal? (test-xyes (list LIM "hi there")) (build-list 20 (λ (x) "hi there")))

;; Runs xyes twice, producing a list with the size of the output bytes
;; The first thread is run for 0.01 seconds, while the second is run for 0.5 seconds
;; NOTE: The size of the output is returned to help with memory/speed from string conversion
;; two-xyes: [Listof String] -> (list Number Number)
(define (two-xyes args)
  (define output1
    (with-output-to-bytes
      (λ ()
        (define worker (thread (λ () (xyes args))))
        (sleep 0.01)
        (kill-thread worker))))
  (define output2
    (with-output-to-bytes
      (λ ()
        (define worker (thread (λ () (xyes args))))
        (sleep 0.05)
        (kill-thread worker))))
  (list (bytes-length output1) (bytes-length output2)))


;; When infinite outputs are produced the first is shorter than the second
(let ([output (two-xyes (list "hello"))])
  (check-true (< (first output) (second output))))
(let ([output (two-xyes '())])
  (check-true (< (first output) (second output))))

;; When a limit is set the outputs have the same length
(let ([output (two-xyes (list LIM))])
  (check-equal? (first output) (second output)))
(let ([output (two-xyes (list LIM "Hello!"))])
  (check-equal? (first output) (second output)))


;; stream implementation tests




