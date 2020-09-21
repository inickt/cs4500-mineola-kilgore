#lang racket

(require racket/cmdline
         rackunit)

(provide xgui)

;+---------------------------------------------------------------------------------------------------+
; Constants

(define ERR-NUM-ARGS "Incorrect number of arguments.\nCorrect usage: ./xgui [positive integer]")
(define ERR-BAD-SIZE
  (string-append "Invalid size, must be an integer greater than 0.\n"
                 "Correct usage: ./xgui [positive integer]"))
;+---------------------------------------------------------------------------------------------------+
; Functions

; Ensures the input is a single positive integer
; Return value should be ignored
; [Listof Str] -> Bool
(define (check-legal-input args)
  (cond [(not (= 1 (length args)))                       (error ERR-NUM-ARGS)]
        [(false? (string->number (first args)))          (error ERR-BAD-SIZE)]
        [(not (positive? (string->number (first args)))) (error ERR-BAD-SIZE)]
        [else #t]))

; Draws a hexagon, closes when the hexagon is clicked
(define (run-hex size)
  (big-bang #t ...))

(define (xgui args)
  (check-legal-input args)
  (define size (string->number (first args)))
  (println size))
