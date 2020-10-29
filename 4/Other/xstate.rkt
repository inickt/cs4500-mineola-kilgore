#lang racket/base

(require lang/posn
         json
         racket/list
         "../../Fish/Common/json.rkt"
         "../../Fish/Common/penguin-color.rkt"
         "../../Fish/Common/state.rkt")

(provide xstate)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xstate : -> void?
;; Read a State from STDIN, applies the first move around the current player's penguin, and writes
;; the resultant state (if possible) to STDOUT.
(define (xstate)
  (define maybe-state (with-handlers ([exn:fail? (λ (exn) #f)])
                        (parse-json-state (read-json))))
  (define maybe-result-state (and maybe-state
                                  (cons? (player-places (first (state-players maybe-state))))
                                  (get-result-state maybe-state)))
  (write-json (and maybe-result-state (serialize-state maybe-result-state)))
  (newline))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS

;; get-result-state : state? -> (or/c false? state?)
;; Using the silly algorithm, gets the next state
(define (get-result-state state)
  ;; We promise we didn't alter our valid-moves function, we just happened to build
  ;; it to return a list of moves by looking N first then moving clockwise...
  (define player-position (first (player-places (state-current-player state))))
  (define potential-moves (valid-moves state player-position))
  (and (cons? potential-moves) (move-penguin state (first potential-moves))))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require rackunit
           racket/path
           "../../Fish/Other/util.rkt")

  ;; Testing helpers
  (define test-board '((1 1 1 1 1) (1 1 1 0 1) (1 1 0 0 1)))
  (define test-players (λ (lop)
                         (list (make-player WHITE 0 lop)
                               (make-player RED 3 (list (make-posn 0 1) (make-posn 0 2))))))
  (define test-state (λ (lop) (make-state test-board (test-players lop))))

  ;; get-result-state
  ;; blocked in by holes and edges
  (define test-1-posn (make-posn 2 4))
  (define test-1-state (test-state (list test-1-posn (make-posn 1 1))))
  (check-false (get-result-state test-1-state))
  ;; blocked in by penguins and edges
  (define test-2-posn (make-posn 0 0))
  (define test-2-state (test-state (list test-2-posn (make-posn 1 1))))
  (check-false (get-result-state test-2-state))
  ;; moves North
  (define test-3-posn (make-posn 1 2))
  (define test-3-state (test-state (list test-3-posn)))
  (check-equal? (get-result-state test-3-state)
                (make-state '((1 1 1 1 1) (1 1 0 0 1) (1 1 0 0 1))
                            (list (make-player RED 3 (list (make-posn 0 1) (make-posn 0 2)))
                                  (make-player WHITE 1 (list (make-posn 1 0))))))
  ;; moves SW
  (define test-4-posn (make-posn 0 3))
  (define test-4-state (test-state (list test-4-posn (make-posn 1 2) (make-posn 1 4))))
  (check-equal? (get-result-state test-4-state)
                (make-state '((1 1 1 0 1) (1 1 1 0 1) (1 1 0 0 1))
                            (list (make-player RED 3 (list (make-posn 0 1) (make-posn 0 2)))
                                  (make-player WHITE 1 (list (make-posn 0 4)
                                                             (make-posn 1 2)
                                                             (make-posn 1 4))))))
  ;; Integration tests
  (check-integration xstate "../Tests/1-in.json" "../Tests/1-out.json")
  (check-integration xstate "../Tests/2-in.json" "../Tests/2-out.json")
  (check-integration xstate "../Tests/3-in.json" "../Tests/3-out.json")

  ;; Fest tests
  (check-fest xstate (build-path "./fest")))
