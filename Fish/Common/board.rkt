#lang racket/base

(require 2htdp/image
         lang/posn
         json
         racket/contract
         racket/format
         racket/list
         "tile.rkt")

;; +-------------------------------------------------------------------------------------------------+

;; A Board is a (vectorof (vectorof tile?)) and uses a doubled coordinate system to represent a grid
;; of tesselated hexagons. The coordinates for a Board following format:
#| TODO: change back to normal coords
(0,0)     (2,0)     (4,0) ... (n,0)
     (1,1)     (3,1)      
(0,2)     (2,2)     (4,2)     (n,2)
     (1,3)     (3,3)
(0,4)     (2,4)     (4,4)     (n,4)
...                            ...
(0,m)     (2,m)     (4,m) ... (n,m)
|#

;; make-board-with-holes : natural? natural? (listof posn?) ... -> board?
#;
(define (make-board-with-holes width height holes ...)
  (foldr remove-tile
         ... ;; TODO: figure out how to make board
         holes)
  ; or
  (define board (make-even-board width height tile)
    (for/list [hole holes]
      (remove-tile hole board))))

;; make-even-board : PosInt PosInt natural? natural? tile? -> board?
;; Create a game board of the given width and height filled with the given tile
(define (make-even-board width height tile)
  (build-vector width (λ (x) (make-vector height tile))))

;; reachable-posns : board? posn? -> (listof posn?)
#;
(define (reachable-posns board current)
  ...)

;; remove-tile! : posn? board? -> board?
;; SIDE EFFECTS: board
;; Removes the tile at the given doubled position from the board
(define (remove-tile! posn board)
  (when (hole? (get-tile posn board))
    (error (~a posn " is already a hole and cannot be removed")))
  (vector-set! (vector-ref board (posn-x posn))
               (posn-y posn)
               0)
  board)

;; get-tile : posn? board? -> tile?
;; Returns the tile at the given (valid) position on the board
(define (get-tile posn board)
  (vector-ref (vector-ref board (posn-x posn))
              (posn-y posn)))

;; draw-board : board? positive? -> image?
;; Draws the given game board
(define (draw-board board size)
  (foldr (λ (tiles sofar)
           (overlay/xy (draw-board-column (vector->list tiles) #t size)
                       (* 4 size) 0
                       sofar))
         empty-image
         (vector->list board)))

;; draw-board-column : (listof tile?) boolean? -> image?
;; Draws a column of tiles
(define (draw-board-column tiles left size)
  (if (empty? tiles)
      empty-image
      (overlay/xy (draw-tile (first tiles) size)
                  (if left 0 (* size -2)) size
                  (draw-board-column (rest tiles) (not left) size))))

;; board-columns : board? -> PosInt
;; Number of columns in the board
(define (board-columns board)
  (vector-length board))

;; board-rows : board? -> PosInt
;; Number of rows in the board
(define (board-rows board)
  (vector-length (vector-ref board 0)))

;; posn-within-board? : Posn Board -> boolean?
;; Is the given position on the board?
(define (posn-within-board? posn board)
  (and (>= (posn-x posn) 0)
       (< (posn-x posn) (board-columns board))
       (>= (posn-y posn) 0)
       (< (posn-y posn) (board-rows board))))

#|

  ______          ______          ______
 /      \        /      \        /      \
/ (0, 0) \______/ (1, 0) \______/ (2, 0) \______
\        /      \        /      \        /      \
 \______/ (0, 1) \______/ (1, 1) \______/ (2, 1) \
 /      \        /      \        /      \        /
/ (0, 2) \______/ (1, 2) \______/ (2, 2) \______/
\        /      \        /      \        /      \
 \______/ (0, 3) \______/ (1, 3) \______/ (2, 3) \
 /      \        /      \        /      \        /
/ (0, 4) \______/ (1, 4) \______/ (2, 4) \______/
\        /      \        /      \        /      \
 \______/ (0, 5) \______/ (1, 5) \______/ (2, 5) \
 /      \        /      \        /      \        / 
/ (0, 6) \______/ (1, 6) \______/ (2, 6) \______/
\        /      \        /      \        /
 \______/        \______/        \______/
|#

(define (top-hexagon-posn posn)
  (make-posn (posn-x posn) (- (posn-y posn) 2)))

(define (bottom-hexagon-posn posn)
  (make-posn (posn-x posn) (+ (posn-y posn) 2)))

(define (right-top-hexagon-posn posn)
  (make-posn (if (even? (posn-y posn))
                 (posn-x posn)
                 (add1 (posn-x posn)))
             (sub1 (posn-y posn))))

(define (right-bottom-hexagon-posn posn)
  (make-posn (if (even? (posn-y posn))
                 (posn-x posn)
                 (add1 (posn-x posn)))
             (add1 (posn-y posn))))

(define (left-top-hexagon-posn posn)
  (make-posn (if (odd? (posn-y posn))
                 (posn-x posn)
                 (sub1 (posn-x posn)))
             (sub1 (posn-y posn))))

(define (left-bottom-hexagon-posn posn)
  (make-posn (if (odd? (posn-y posn))
                 (posn-x posn)
                 (sub1 (posn-x posn)))
             (add1 (posn-y posn))))


;; valid-movements : Posn Board -> (listof Posn)
(define (valid-movements posn board)
  (append (valid-movements-direction posn board top-hexagon-posn)
          (valid-movements-direction posn board bottom-hexagon-posn)
          (valid-movements-direction posn board right-top-hexagon-posn)
          (valid-movements-direction posn board right-bottom-hexagon-posn)
          (valid-movements-direction posn board left-top-hexagon-posn)
          (valid-movements-direction posn board left-bottom-hexagon-posn)))

(define (valid-movements-direction posn board mover)
  (define moved (mover posn))
  (if (and (posn-within-board? moved board) (not (hole? (get-tile moved board))))
      (cons moved (valid-movements-direction moved board mover))
      '()))
  
  

;; +-------------------------------------------------------------------------------------------------+

(module+ test
  (require rackunit)
  ;; make-even-board
  (check-equal? (make-even-board 1 1 2) #(#(2)))
  (check-equal? (make-even-board 2 3 1)
                #(#(1 1 1)
                  #(1 1 1)))
  (check-equal? (make-even-board 3 2 4)
                #(#(4 4)
                  #(4 4)
                  #(4 4)))
  ;; remove-tile!
  (check-equal? (remove-tile! (make-posn 0 0) (make-even-board 2 3 1))
                #(#(0 1 1)
                  #(1 1 1)))
  (check-equal? (remove-tile! (make-posn 0 1) (make-even-board 2 3 1))
                #(#(1 0 1)
                  #(1 1 1)))
  (check-equal? (remove-tile! (make-posn 2 1) (make-even-board 3 2 2))
                #(#(2 2)
                  #(2 2)
                  #(2 0)))
  (check-exn exn:fail? (λ () (remove-tile! (make-posn 2 1)
                                           #(#(2 2)
                                             #(2 2)
                                             #(2 0))))))
  









