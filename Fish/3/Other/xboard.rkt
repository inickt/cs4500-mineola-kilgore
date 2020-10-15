#lang racket/base

(require json
         lang/posn
         racket/list
         "../../Common/board.rkt")

(provide xboard)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xboard : -> void?
;; Reads a valid and well formed Board-Posn from STDIN, and then writes the count of reachable tiles
;; on the board from the specified tile to STDOUT
(define (xboard)
  (define json-obj (read-json))
  (write-json (count-reachable-tiles (parse-posn-from-input (hash-ref json-obj 'position))
                                     (transpose-matrix (hash-ref json-obj 'board)))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS

;; transpose-matrix : (non-empty-listof (non-empty-listof any/c)) -> (listof (listof any/c))
;; Transposes a matrix represented as a 2d list
(define (transpose-matrix mat)
  (apply map list mat))

;; parse-posn-from-input : (listof natural?) -> posn?
;; Parses a (column, row) posn from a (list row column)
(define (parse-posn-from-input lon)
  (make-posn (second lon) (first lon)))

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
                "1")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 0 board-str-1) xboard)))
                "2")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 2 board-str-1) xboard)))
                "1")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 0 0 board-str-2) xboard)))
                "3")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 0 board-str-2) xboard)))
                "4")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 0 2 board-str-2) xboard)))
                "1")
  (check-equal? (with-output-to-string
                  (λ () (with-input-from-string (build-example 1 2 board-str-2) xboard)))
                "1")

  ;; Internal Helper Functions
  ;; transpose-matrix
  (check-equal? (transpose-matrix '((1))) '((1)))
  (check-equal? (transpose-matrix '((1 2 3) (4 5 6) (7 8 9))) '((1 4 7) (2 5 8) (3 6 9)))
  ;; parse-posn-from-input
  (check-equal? (parse-posn-from-input '(1 4)) (make-posn 4 1))
  (check-equal? (parse-posn-from-input '(6 0)) (make-posn 0 6))
  ;; count-reachable-tiles
  (check-equal? (count-reachable-tiles (make-posn 0 0) '((1)))
                0)
  (check-equal? (count-reachable-tiles (make-posn 0 0) '((1 4) (2 0) (3 5)))
                1)
  (check-equal? (count-reachable-tiles (make-posn 0 1) '((1 4 1) (2 0 1) (3 5 0)))
                4))