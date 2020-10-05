#lang racket/base

(require 2htdp/image
         racket/math
         lang/posn)

(define TILE-BACKGROUND-COLOR "SkyBlue")
(define TILE-HOLE-BACKGROUND-COLOR "LightGray")
(define TILE-OUTLINE-COLOR "Black")
(define TILE-MAX-FISH 5)
(define FISH
  (overlay/offset
   (circle 2 'solid 'black)
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
      'blue)
     78 15 250 1/2
     80 25 100 1/2
     'black)
    65 20 200 3/2
    70 27 0 1
    'black)))

;; A Tile is a natural number.
;; - 0 is a hole/tile with no fish
;; - Otherwise it represents the number of fish on a tile

;; tile? : any? -> boolean?
;; Is the given item a tile?
(define (tile? tile)
  (natural? tile))

;; hole? : tile? -> boolean?
;; Is the given tile a hole?
(define (hole? tile)
  (zero? tile))

;; draw-tile : tile? size -> image?
;; Draws a tile with the given number of fish, or a hole tile if empty
;; The size of the resulting image has a height of 2*size and a width of 3*size
(define (draw-tile tile size)
  (define fish-size (* 2 (/ size (add1 (max tile TILE-MAX-FISH)))))
  (define background-color (if (hole? tile) TILE-HOLE-BACKGROUND-COLOR TILE-BACKGROUND-COLOR))
  (overlay (draw-fish-stack tile fish-size)
           (draw-hexagon size "outline" TILE-OUTLINE-COLOR)
           (draw-hexagon size "solid" background-color)))

;; draw-fish-stack : tile? positive? -> image?
;; Draws the given number of fish stacked, where each fish has the given height
(define (draw-fish-stack tile height)
  (if (hole? tile)
      empty-image
      (above (scale (/ height (image-height FISH)) FISH)
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
