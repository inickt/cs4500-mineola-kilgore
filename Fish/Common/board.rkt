#lang racket/base

(provide ;board?
 ;make-board-with-holes
 make-even-board
 remove-tile!)

(require 2htdp/image
         lang/posn
         racket/contract
         racket/format
         racket/list
         racket/vector
         "tile.rkt")

;; TODO:
;; - provide with contracts
;; - clarity comments
;; - test test test
;; - design task

;; +-------------------------------------------------------------------------------------------------+
;; CONSTANTS

(define MAX-FISH-PER-TILE 5)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; A Board is a (vectorof (vectorof tile?)) and uses an offset coordinate system to represent a grid
;; of tesselated hexagons.
;;
;; The following is a visual representation of a 3x7 board:
;;     ______          ______          ______
;;    /      \        /      \        /      \
;;   / (0, 0) \______/ (1, 0) \______/ (2, 0) \______
;;   \        /      \        /      \        /      \
;;    \______/ (0, 1) \______/ (1, 1) \______/ (2, 1) \
;;    /      \        /      \        /      \        /
;;   / (0, 2) \______/ (1, 2) \______/ (2, 2) \______/
;;   \        /      \        /      \        /      \
;;    \______/ (0, 3) \______/ (1, 3) \______/ (2, 3) \
;;    /      \        /      \        /      \        /
;;   / (0, 4) \______/ (1, 4) \______/ (2, 4) \______/
;;   \        /      \        /      \        /      \
;;    \______/ (0, 5) \______/ (1, 5) \______/ (2, 5) \
;;    /      \        /      \        /      \        /
;;   / (0, 6) \______/ (1, 6) \______/ (2, 6) \______/
;;   \        /      \        /      \        /
;;    \______/        \______/        \______/
;;

;; board? : any/c -> boolean?
;; Is the given value a board?
(define (board? value)
  ((and/c (vectorof (and/c (vectorof tile? #:flat? #t)
                           (not/c vector-empty?))
                    #:flat? #t)
          (not/c vector-empty?))
   value))

;; make-board-with-holes : natural? natural? (listof posn?) natural? -> board?
;; Creates a board with 
(define (make-board-with-holes width height holes min-1s [max-fish MAX-FISH-PER-TILE])
  (define filtered-holes
    (filter (λ (hole) (posn-within-bounds? hole width height)) holes))
  (define num-tiles (- (* width height) (length filtered-holes)))
  
  ;; Error checking
  (when (or (<= width 0) (<= height 0))
    (error (~a "Error: cannot build a board with width " width " and/or height " height)))
  (when (< num-tiles min-1s)
    (error (~a "Error: Impossible to create a board with the specified holes "
               "and min number of 1-fish tiles")))
  
  (define start-board (make-even-board width height 0))
  (define random-tiles (random-list-with-min-1s num-tiles min-1s max-fish))
  (displayln random-tiles)
  (for ([x (build-list width (λ (x) x))])
    (for ([y (build-list height (λ (x) x))]
          #:unless (member (make-posn x y) filtered-holes))
      (set-tile! (make-posn x y)
                 (first random-tiles)
                 start-board)
      (set! random-tiles (rest random-tiles))))
  start-board)

;; make-even-board : PosInt PosInt natural? natural? tile? -> board?
;; Create a game board of the given width and height filled with the given tile
(define (make-even-board width height tile)
  (build-vector width (λ (x) (make-vector height tile))))

;; remove-tile! : posn? board? -> board?
;; SIDE EFFECTS: board
;; Removes the tile at the given doubled position from the board
(define (remove-tile! posn board)
  (when (hole? (get-tile posn board))
    (error (~a posn " is already a hole and cannot be removed")))
  (set-tile! posn 0 board))

;; valid-movements : posn? board? -> (listof posn?)
;; Creates a list of valid movements on the board, starting from the top and moving clockwise
(define (valid-movements posn board)
  ;; TODO: Add error when posn is a hole
  (define (moves mover)
    (valid-movements-direction posn board mover))
  (append (moves top-hexagon-posn)
          (moves top-right-hexagon-posn)
          (moves bottom-right-hexagon-posn)
          (moves bottom-hexagon-posn)
          (moves bottom-left-hexagon-posn)
          (moves top-left-hexagon-posn)))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; get-tile : posn? board? -> tile?
;; Returns the tile at the given (valid) position on the board
(define (get-tile posn board)
  (vector-ref (vector-ref board (posn-x posn))
              (posn-y posn)))

;; board-columns : board? -> PosInt
;; Number of columns in the board
(define (board-columns board)
  (vector-length board))

;; board-rows : board? -> PosInt
;; Number of rows in the board
(define (board-rows board)
  (vector-length (vector-ref board 0)))

;; posn-within-bounds? : posn? natural? natural? -> boolean?
;; Is the given posn-x on [0, width) and posn-y on [0, height)?
(define (posn-within-bounds? posn width height)
  (and (>= (posn-x posn) 0)
       (< (posn-x posn) width)
       (>= (posn-y posn) 0)
       (< (posn-y posn) height)))

;; set-tile! : posn? tile? board? -> board?
;; Sets the tile at the given posn on the board
(define (set-tile! posn new-tile board)
  (vector-set! (vector-ref board (posn-x posn))
               (posn-y posn)
               new-tile)
  board)

;; draw-board : board? positive? -> image?
;; Draws the given game board
(define (draw-board board size)
  (foldr (λ (tiles sofar)
           (overlay/xy (draw-board-column (vector->list tiles) size)
                       (* 4 size) 0
                       sofar))
         empty-image
         (vector->list board)))

;; draw-board-column : (listof tile?) positive? [boolean?] -> image?
;; Draws a column of tiles
(define (draw-board-column tiles size [left #t])
  (if (empty? tiles)
      empty-image
      (overlay/xy (draw-tile (first tiles) size)
                  ;; if this tile is on the right, then we need to shift the
                  ;; recursively drawn image left, hence using -2
                  (if left 0 (* size -2))
                  size
                  (draw-board-column (rest tiles) size (not left)))))

;; random-list-with-min-1s : natural? natural? natural? -> (listof tile?)
;; INVARIANT: size >= min-1s
;; Builds a list of tiles with no holes, a max size for each tile, and a minimum number of 1s
(define (random-list-with-min-1s size min-1s max-tile-size)
  (shuffle (append (build-list min-1s (λ (x) 1))
                   (build-list (- size min-1s) (λ (x) (add1 (random max-tile-size)))))))

;; top-hexagon-posn : posn? -> posn?
;; Produces the position directly above the given hexagon coordinate position
(define (top-hexagon-posn posn)
  (make-posn (posn-x posn) (- (posn-y posn) 2)))

;; bottom-hexagon-posn : posn? -> posn?
;; Produces the position directly below the given hexagon coordinate position
(define (bottom-hexagon-posn posn)
  (make-posn (posn-x posn) (+ (posn-y posn) 2)))

;; top-right-hexagon-posn : posn? -> posn?
;; Produces the position directly to the top right of the given hexagon coordinate position
(define (top-right-hexagon-posn posn)
  (make-posn (if (even? (posn-y posn))
                 (posn-x posn)
                 (add1 (posn-x posn)))
             (sub1 (posn-y posn))))

;; bottom-right-hexagon-posn : posn? -> posn?
;; Produces the position directly to the bottom right of the given hexagon coordinate position
(define (bottom-right-hexagon-posn posn)
  (make-posn (if (even? (posn-y posn))
                 (posn-x posn)
                 (add1 (posn-x posn)))
             (add1 (posn-y posn))))

;; top-left-hexagon-posn : posn? -> posn?
;; Produces the position directly to the top left of the given hexagon coordinate position
(define (top-left-hexagon-posn posn)
  (make-posn (if (odd? (posn-y posn))
                 (posn-x posn)
                 (sub1 (posn-x posn)))
             (sub1 (posn-y posn))))

;; bottom-left-hexagon-posn : posn? -> posn?
;; Produces the position directly to the bottom left of the given hexagon coordinate position
(define (bottom-left-hexagon-posn posn)
  (make-posn (if (odd? (posn-y posn))
                 (posn-x posn)
                 (sub1 (posn-x posn)))
             (add1 (posn-y posn))))

;; valid-movements-direction : posn? board? (posn? -> posn?) -> (listof posn?)
;; Creates a list of valid movements on the board in a given direction
(define (valid-movements-direction posn board mover)
  (define moved (mover posn))
  (if (and (posn-within-bounds? moved (board-columns board) (board-rows board))
           (not (hole? (get-tile moved board))))
      (cons moved (valid-movements-direction moved board mover))
      '()))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

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
  









