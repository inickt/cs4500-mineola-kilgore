#lang racket

(require 2htdp/image
         2htdp/universe
         lang/posn
         rackunit)

(provide xgui)

;+---------------------------------------------------------------------------------------------------+
; Constants

(define ERR-NUM-ARGS "Incorrect number of arguments.
Correct usage: ./xgui [positive integer]")
(define ERR-BAD-SIZE "Invalid size, must be an integer greater than 0.
Correct usage: ./xgui [positive integer]")

;+---------------------------------------------------------------------------------------------------+
; Functions

; check-legal-input: [Listof Str] -> void?
; Validates the input is a single positive integer or throws an error
(define (check-legal-input args)
  (cond [(not (= 1 (length args)))                       (error ERR-NUM-ARGS)]
        [(false? (string->number (first args)))          (error ERR-BAD-SIZE)]
        [(not (positive? (string->number (first args)))) (error ERR-BAD-SIZE)]
        [else void]))

(check-exn exn:fail? (λ () (check-legal-input '())))
(check-exn exn:fail? (λ () (check-legal-input '("100" "200"))))
(check-exn exn:fail? (λ () (check-legal-input '("hello"))))
(check-exn exn:fail? (λ () (check-legal-input '("0"))))
(check-exn exn:fail? (λ () (check-legal-input '("-100"))))
(check-equal? (check-legal-input '("100")) void)

; hexagon-clicked: Nat Int Int MouseEvent -> HandlerResult
; Stops the world if a mouse click is within the given hexagon size
(define (hexagon-clicked size x y me)
  (if (and (string=? me "button-down")
           (>= y 0)
           (<= y (* 2 size))
           (>= y (- size x))
           (>= y (- x (* 2 size)))
           (<= y (+ x size))
           (<= y (- (* 4 size) x)))
      (stop-with size)
      size))

(check-equal? (hexagon-clicked 10 0 0 "move") 10)
; corners
(check-equal? (hexagon-clicked 10 10 0 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 0 10 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 30 10 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 20 0 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 20 20 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 10 20 "button-down") (stop-with 10))
; edges
(check-equal? (hexagon-clicked 10 5 5 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 15 0 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 25 5 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 25 15 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 15 20 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 5 15 "button-down") (stop-with 10))
; inside
(check-equal? (hexagon-clicked 10 9 9 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 15 5 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 21 9 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 21 11 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 15 15 "button-down") (stop-with 10))
(check-equal? (hexagon-clicked 10 9 11 "button-down") (stop-with 10))
; outside
(check-equal? (hexagon-clicked 10 0 0 "button-down") 10)
(check-equal? (hexagon-clicked 10 4 5 "button-down") 10)
(check-equal? (hexagon-clicked 10 5 4 "button-down") 10)
(check-equal? (hexagon-clicked 10 15 -1 "button-down") 10)
(check-equal? (hexagon-clicked 10 25 4 "button-down") 10)
(check-equal? (hexagon-clicked 10 25 16 "button-down") 10)
(check-equal? (hexagon-clicked 10 15 21 "button-down") 10)
(check-equal? (hexagon-clicked 10 5 16 "button-down") 10)

; draw-hexagon: PosInt -> Image
; Draws a hexagon with the givan size
(define (draw-hexagon size)
  (polygon (list (make-posn 0 size)
                 (make-posn size 0)
                 (make-posn (* 2 size) 0)
                 (make-posn (* 3 size) size)
                 (make-posn (* 2 size) (* 2 size))
                 (make-posn size (* 2 size)))
           "outline"
           "red"))

; run-hex: PosInt -> PosInt
; Draws a hexagon, closes when the hexagon is clicked
(define (run-hex size)
  (big-bang size
    [on-mouse hexagon-clicked]
    [to-draw draw-hexagon]
    [close-on-stop #t]
    [name "xgui"]))

; xgui: [Listof Str] -> void?
; Opens a gui with a hexagon of the provided size, and closes once it is clicked
(define (xgui args)
  (check-legal-input args)
  (define size (string->number (first args)))
  ; suppress printing the final world state to stdout
  (with-output-to-string (λ () (run-hex size)))
  (void))
