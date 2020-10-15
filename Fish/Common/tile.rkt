#lang racket/base

(require 2htdp/image
         racket/contract
         racket/math
         lang/posn)

(provide (contract-out [tile? (-> any/c boolean?)])
         (contract-out [hole? (-> tile? boolean?)])
         (contract-out [draw-tile (-> tile? positive? image?)])
         tile-width
         tile-height)

;; +-------------------------------------------------------------------------------------------------+
;; CONSTANTS

(define TILE-BACKGROUND-COLOR 'skyblue)
(define TILE-HOLE-BACKGROUND-COLOR 'lightgray)
(define TILE-OUTLINE-COLOR 'black)
(define TILE-FISH-SCALE-CUTOFF 5)

(define FISH-COLOR 'coral)
(define FISH-FEATURE-COLOR 'black)
(define FISH-IMAGE
  (overlay/offset
   (circle 2 'solid FISH-FEATURE-COLOR)
   -37 1
   (add-curve
    (add-curve
     (polygon
      (list (make-pulled-point 1/2 12 5 0 1/2 -12)
            (make-posn 0 20)
            (make-pulled-point 1/2 -20 20 10 5/8 15)
            (make-posn 100 10)
            (make-pulled-point 1/2 -20 100 10 0 0)
            (make-posn 90 7)
            (make-pulled-point 1/2 -20 105 5 1/2 40)
            (make-posn 100 -5)
            (make-pulled-point 3/4 -24 20 -10 1/2 20)
            (make-posn 0 -20))
      'solid
      FISH-COLOR)
     78 15 250 1/2
     80 25 100 1/2
     FISH-FEATURE-COLOR)
    65 20 200 3/2
    70 27 0 1
    FISH-FEATURE-COLOR)))

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; A Tile is a natural number.
;; - 0 is a hole/tile with no fish
;; - Otherwise it represents the number of fish on a tile

;; tile? : any/c -> boolean?
;; Is the given item a tile?
(define tile? natural?)

;; hole? : tile? -> boolean?
;; Is the given tile a hole?
(define hole? zero?)

;; draw-tile : tile? positive? -> image?
;; Draws a tile with the given number of fish, or a hole tile if empty
;; The size of the resulting image has a height of (tile-height size) and a (tile-width size)
(define (draw-tile tile size)
  ;; pixel height of each fish will be the same for each fish under TILE-FISH-SCALE-CUTOFF,
  ;; or scaled proportionally to fit more fish if above TILE-FISH-SCALE-CUTOFF.
  ;; add1 to add half a fish height above and below
  (define fish-height (* 2 (/ size (add1 (max tile TILE-FISH-SCALE-CUTOFF)))))
  (define background-color (if (hole? tile) TILE-HOLE-BACKGROUND-COLOR TILE-BACKGROUND-COLOR))
  (overlay (draw-fish-stack tile fish-height)
           (draw-hexagon size 'outline TILE-OUTLINE-COLOR)
           (draw-hexagon size 'solid background-color)))

(define (tile-width size)
  (* 3 size))

(define (tile-height size)
  (* 2 size))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; draw-fish-stack : tile? positive? -> image?
;; Draws the given number of fish stacked, where each fish has the given height
(define (draw-fish-stack tile height)
  (if (hole? tile)
      empty-image
      (above (scale (/ height (image-height FISH-IMAGE)) FISH-IMAGE)
             (draw-fish-stack (sub1 tile) height))))

;; draw-hexagon : natural? mode? image-color? -> image?
;; Draws a hexagon with the givan size, drawing mode, and color
;; The size of the resulting image has a height of 2*size and a width of 3*size
(define (draw-hexagon size mode color)
  (polygon (list (make-posn 0 size)
                 (make-posn size 0)
                 (make-posn (* 2 size) 0)
                 (make-posn (* 3 size) size)
                 (make-posn (* 2 size) (* 2 size))
                 (make-posn size (* 2 size)))
           mode
           color))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)
  ;; draw-tile
  (check-equal? (image-width (draw-tile 0 10)) 30)
  (check-equal? (image-height (draw-tile 0 10)) 20)
  (check-equal? (image-width (draw-tile 3 100)) 300)
  (check-equal? (image-height (draw-tile 3 100)) 200)
  ;; draw-fish-stack
  (check-equal? (image-height (draw-fish-stack 0 5)) 0)
  (check-equal? (image-height (draw-fish-stack 1 5)) 5)
  (check-equal? (image-height (draw-fish-stack 2 5)) 10)
  ;; draw-hexagon
  (check-equal? (image-width (draw-hexagon 10 'solid 'black)) 30)
  (check-equal? (image-height (draw-hexagon 10 'solid 'black)) 20)
  (check-equal? (image-width (draw-hexagon 100 'solid 'black)) 300)
  (check-equal? (image-height (draw-hexagon 100 'solid 'black)) 200))
