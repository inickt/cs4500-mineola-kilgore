#lang racket/base

(require lang/posn
         racket/list
         "../../Fish/Common/penguin.rkt"
         "../../Fish/Common/state.rkt")

(provide xstate)

;; apply-algorithm : penguin? posn? [listof posn?] state -> (or/c false? state?)
;; attempts to make the list of moves in order, or #false if all fail
(define (apply-algorithm penguin cur-posn algo-moves state)
  (if (empty? algo-moves) #f (move-penguin penguin cur-posn (first algo-moves) state)))

(define (xstate)
  ;; TODO parse board, penguin, and cur-posn from input
  (define state (make-state '((0 1 0) (1 0 1))
                            (list (make-player WHITE 0 (list (make-posn 0 1)))
                                  (make-player RED 4 (list (make-posn 1 0))))))
  (define penguin RED)
  (define cur-posn (make-posn 1 0))

  ;; We promise we didn't alter our valid-moves function, we just happened to build
  ;; it to return a list of moves by looking N first then moving clockwise...
  (define algo-moves (valid-moves cur-posn state))

  ;; TODO write JSON result
  (define result-state (apply-algorithm penguin cur-posn algo-moves state))
  (displayln result-state)
  (draw-state result-state 50))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require rackunit)

  ;; Testing helpers
  (define test-board '((1 1 1 1 1) (1 1 1 0 1) (1 1 0 0 1)))
  (define test-players (λ (lop)
                         (list (make-player WHITE 0 lop)
                               (make-player RED 3 (list (make-posn 0 1) (make-posn 0 2))))))
  (define test-state (λ (lop) (make-state test-board (test-players lop))))
  (define apply-test (λ (posn state) (apply-algorithm WHITE posn (valid-moves posn state) state)))
  
  ;; apply-algorithm
  ;; blocked in by holes and edges
  (define test-1-posn (make-posn 2 4))
  (define test-1-state (test-state (list test-1-posn (make-posn 1 1))))
  (check-false (apply-test test-1-posn test-1-state))
  ;; blocked in by penguins and edges
  (define test-2-posn (make-posn 0 0))
  (define test-2-state (test-state (list test-2-posn (make-posn 1 1))))
  (check-false (apply-test test-2-posn test-2-state))
  ;; moves North
  (define test-3-posn (make-posn 1 2))
  (define test-3-state (test-state (list test-3-posn)))
  (check-equal? (apply-test test-3-posn test-3-state)
                (make-state '((1 1 1 1 1) (1 1 0 0 1) (1 1 0 0 1))
                            (list (make-player WHITE 1 (list (make-posn 1 0)))
                                  (make-player RED 3 (list (make-posn 0 1) (make-posn 0 2))))))
  ;; moves SW
  (define test-4-posn (make-posn 0 3))
  (define test-4-state (test-state (list test-4-posn (make-posn 1 2) (make-posn 1 4))))
  (check-equal? (apply-test test-4-posn test-4-state)
                (make-state '((1 1 1 0 1) (1 1 1 0 1) (1 1 0 0 1))
                            (list (make-player WHITE 1
                                               (list (make-posn 0 4) (make-posn 1 2) (make-posn 1 4)))
                                  (make-player RED 3 (list (make-posn 0 1) (make-posn 0 2)))))))
  