#lang racket/base

(require json
         lang/posn
         racket/list
         "../../Common/board.rkt")

(provide xboard)

;; parse-board-from-input : (hashof string? list?) -> board?
;; Parses the board from the input JSON dictionary
(define (parse-board-from-input board-in)
  (make-board-from-2d-list (transpose-matrix board-in)))

;; transpose-matrix : (listof (listof any?)) -> (listof (listof any?))
;; Transposes a matrix represented as a 2d list
(define (transpose-matrix mat)
  (apply map list mat))

;; parse-posn-from-input : (listof natural?) -> posn?
;; Parses a (column, row) posn from a (list row column)
(define (parse-posn-from-input lon)
  (make-posn (second lon) (first lon)))

;; count-reachable-tiles : Posn Board -> Natural
;; Counts the tiles reachable from the given posn on the board, assuming the posn is a non-hole tile
(define (count-reachable-tiles posn board)
  (length (valid-movements posn board)))

(define (xboard)
  (define json-obj (read-json))
  (write-json (count-reachable-tiles (parse-posn-from-input (hash-ref json-obj 'position))
                                     (parse-board-from-input (hash-ref json-obj 'board)))))