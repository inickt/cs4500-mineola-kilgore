#lang racket/base

(require json
         lang/posn
         racket/list
         racket/promise
         "../../Fish/Common/board.rkt"
         "../../Fish/Common/json.rkt"
         "../../Fish/Common/game-tree.rkt"
         "../../Fish/Common/penguin-color.rkt"
         "../../Fish/Common/state.rkt"
         "../../Fish/Player/strategy.rkt")

(provide xstrategy)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xstrategy : -> void?
;; 
(define (xstrategy)
  (write-json #f)
  (newline))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS


;; +-------------------------------------------------------------------------------------------------+
;; TESTS
#;
(module+ test
  (require lang/posn
           rackunit
           "../../Fish/Other/util.rkt")
  
  ;; Integration tests
  (check-integration xstrategy "../Tests/1-in.json" "../Tests/1-out.json")
  (check-integration xstrategy "../Tests/2-in.json" "../Tests/2-out.json")
  (check-integration xstrategy "../Tests/3-in.json" "../Tests/3-out.json")
  (check-integration xstrategy "../Tests/4-in.json" "../Tests/4-out.json")
  (check-integration xstrategy "../Tests/5-in.json" "../Tests/5-out.json"))
