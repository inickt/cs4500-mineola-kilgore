#lang racket/base

(require racket/engine)

(provide run-with-timeout)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; run-with-timeout : (X Y) (-> X) (X -> Y) positive? -> (or/c Y false?)
;; Runs run-proc for up to timeout seconds, then calls result-proc on the result value
;; Returns false if run-proc times out, or if either run-proc or result-proc error
(define (run-with-timeout run-proc result-proc timeout)
  (define run-engine (engine (λ (_) (run-proc))))
  (with-handlers ([exn:fail? (λ (exn) #f)])
    (engine-run (* timeout 1000) run-engine)
    (and (engine-result run-engine) (result-proc (engine-result run-engine)))))
  
;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)
  ;; +--- run-with-timeout ---+
  (check-false (run-with-timeout (λ () (sleep 10)) (λ (result) result) 0.01))
  (check-false (run-with-timeout (λ () (error "Error")) (λ (result) result) 10))
  (check-equal? (run-with-timeout (λ () 1) (λ (result) (and (= result 1) 7)) 0.1) 7))
