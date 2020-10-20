#lang racket/base

(require json
         lang/posn
         racket/list
         "../../Fish/Common/board.rkt"
         "../../Fish/Common/json.rkt")

(provide xboard)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xboard : -> void?
;; Reads a valid and well formed Board-Posn from STDIN, and then writes the count of reachable tiles
;; on the board from the specified tile to STDOUT
(define (xboard)
  (define board-posn (parse-json-board-posn (read-json)))
  (write-json (count-reachable-tiles (board-posn-posn board-posn) (board-posn-board board-posn)))
  (newline))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS

;; count-reachable-tiles : posn? board? -> natural?
;; Counts the tiles reachable from the given posn on the board, assuming the posn is a non-hole tile
(define (count-reachable-tiles posn board)
  (length (valid-movements posn board)))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require racket/port
           rackunit)
  
  ;; Provided Functions
  ;; xboard
  (define board-str-1 "[[1,2,3],[4,0,5]]")
  (define board-str-2 "[[1,2,3],[4,0,5],[1,1,0]]")
  (define (build-example row col board)
    (string-append "{\"board\":"
                   board
                   ",\"position\":["
                   (number->string row)
                   ","
                   (number->string col)
                   "]}"))
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 0 0 board-str-1) xboard)))
                "1\n")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 0 board-str-1) xboard)))
                "2\n")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 2 board-str-1) xboard)))
                "1\n")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 0 0 board-str-2) xboard)))
                "3\n")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 0 board-str-2) xboard)))
                "4\n")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 0 2 board-str-2) xboard)))
                "1\n")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 2 board-str-2) xboard)))
                "1\n")

  ;; Internal Helper Functions
  ;; count-reachable-tiles
  (check-equal? (count-reachable-tiles (make-posn 0 0) '((1)))
                0)
  (check-equal? (count-reachable-tiles (make-posn 0 0) '((1 4) (2 0) (3 5)))
                1)
  (check-equal? (count-reachable-tiles (make-posn 0 1) '((1 4 1) (2 0 1) (3 5 0)))
                4))
