#lang racket/base

(require 2htdp/image
         racket/bool
         racket/contract)

(provide penguin?
         penguin=?
         draw-penguin
         PENGUIN-COLORS)

;; A Penguin is one of:
;; - 'red
;; - 'white
;; - 'brown
;; - 'black
;; and represents a penguin of a given color.

(define RED 'red)
(define WHITE 'white)
(define BROWN 'brown)
(define BLACK 'black)
(define PENGUIN-COLORS (list RED WHITE BROWN BLACK))
(define penguin? (symbols RED WHITE BROWN BLACK))
(define penguin=? symbol=?)

;; draw-penguin : penguin? positive? -> image?
;; Creates an image a penguin with the given height
(define (draw-penguin penguin height)
  (define image (penguin-image penguin))
  (scale (/ height (image-height image)) image))

(define PENGUIN-SECONDARY-COLOR 'white)
(define PENGUIN-ACCENT-COLOR 'yellow)

;; penguin-image : penguin? -> image?
;; Draws the penguin
(define (penguin-image penguin)
  (define pen-color (penguin-color-map penguin))
  (overlay/offset
   (overlay/offset (overlay (circle 2 'solid 'white) (circle 3 'solid 'black))
                   20 0
                   (overlay (circle 2 'solid 'white) (circle 3 'solid 'black)))
   0 26
   (draw-with-outline
    (draw-with-outline
     (draw-with-outline
      (draw-with-outline
       (draw-with-outline
        empty-image
        0 100 90 2.5
        50 100 -90 2.5
        pen-color)
       1 100 -90 0.5
       50 100 90 0.5
       pen-color)
      10 100 90 2.5
      40 100 -90 2.5
      PENGUIN-SECONDARY-COLOR)
     10 100 -90 0.5
     40 100 90 0.5
     PENGUIN-SECONDARY-COLOR)
    20 38 -90 2
    30 38 90 2
    PENGUIN-ACCENT-COLOR)))

;; draw-with-outline : image? real? real? angle? real? real? real? angle? real? color? -> image?
;; Draws a solid curve of the given color with a black outline
(define (draw-with-outline im x1 y1 ang1 str1 x2 y2 ang2 str2 color)
  (add-curve (add-solid-curve im x1 y1 ang1 str1 x2 y2 ang2 str2 color)
             x1 y1 ang1 str1 x2 y2 ang2 str2 'black))

;; penguin-color-map : penguin? -> color?
;; Maps a penguin to a more aesthetically pleasing color
(define (penguin-color-map penguin)
  (cond [(penguin=? penguin WHITE) 'gainsboro]
        [(penguin=? penguin BROWN) 'peru]
        [(penguin=? penguin RED) 'firebrick]
        [(penguin=? penguin BLACK) BLACK]))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)
  ;; draw-penguin
  (check-equal? (image-height (draw-penguin WHITE 20)) 20)
  (check-equal? (image-height (draw-penguin BLACK 40)) 40))
