#lang racket/base

(require 2htdp/image
         racket/bool
         racket/contract
         racket/set)

(provide (contract-out [penguin? (-> any/c boolean?)])
         (contract-out [penguin=? (-> penguin? penguin? boolean?)])
         (contract-out [draw-penguin (-> penguin? positive? image?)])
         (contract-out [penguin-color-map (-> penguin? image-color?)])
         (contract-out [describe-penguin (-> penguin? string?)])
         (contract-out [RED penguin?])
         (contract-out [WHITE penguin?])
         (contract-out [BROWN penguin?])
         (contract-out [BLACK penguin?])
         (contract-out [PENGUIN-COLORS (set/c penguin?)]))

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

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
(define PENGUIN-COLORS (set RED WHITE BROWN BLACK))
(define penguin? (symbols RED WHITE BROWN BLACK))
(define penguin=? symbol=?)
;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; draw-penguin : penguin? positive? -> image?
;; Creates an image a penguin with the given height
(define (draw-penguin penguin height)
  (define image (penguin-image penguin))
  (scale (/ height (image-height image)) image))

;; penguin-color-map : penguin? -> image-color?
;; Maps a penguin to a more aesthetically pleasing color
(define (penguin-color-map penguin)
  (cond [(penguin=? penguin WHITE) 'gainsboro]
        [(penguin=? penguin BROWN) 'peru]
        [(penguin=? penguin RED) 'crimson]
        [(penguin=? penguin BLACK) BLACK]))

;; describe-penguin : penguin? -> string?
;; String representation of the penguin
(define (describe-penguin penguin)
  (string-titlecase (symbol->string penguin)))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

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

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)
  ;; draw-penguin
  (for ([penguin PENGUIN-COLORS])
    (check-equal? (image-height (draw-penguin penguin 20)) 20)
    (check-equal? (image-height (draw-penguin penguin 40)) 40))
  ;; describe-penguin
  (check-equal? (describe-penguin RED) "Red"))
