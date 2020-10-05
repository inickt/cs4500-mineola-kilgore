#lang racket/base

(require 2htdp/image
         racket/math
         lang/posn)

(define TILE-BACKGROUND-COLOR "SkyBlue")
(define TILE-HOLE-BACKGROUND-COLOR "LightGray")
(define TILE-OUTLINE-COLOR "Black")
(define TILE-MAX-FISH 5)

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
  (define fish-size (/ size (add1 (max tile TILE-MAX-FISH))))
  (define background-color (if (hole? tile) TILE-HOLE-BACKGROUND-COLOR TILE-BACKGROUND-COLOR))
  (overlay (draw-fish tile fish-size)
           (draw-hexagon size "outline" TILE-OUTLINE-COLOR)
           (draw-hexagon size "solid" background-color)))

;; draw-fish : tile? size -> image?
;; Draws the given number of fish above eachother at the given size
(define (draw-fish tile size)
  (if (hole? tile)
      empty-image
      (above (circle size "outline" "red")
             (draw-fish (sub1 tile) size))))

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
