#lang racket/base

(require 2htdp/image
         lang/posn
         racket/contract
         racket/format
         racket/lsist
         racket/math
         racket/vector
         "tile.rkt")

(provide (contract-out [board? (-> any/c boolean?)])
         (contract-out [make-board-with-holes (-> posint? posint? (listof posn?) natural? board?)])
         (contract-out [make-even-board (-> posint? posint? tile? board?)])
         (contract-out [remove-tile! (-> posn? board? board?)])
         (contract-out [valid-movements (-> posn? board? (listof posn?))]))

;; TODO:
;; - test test test
;; - design task
;; - readme
;; - testme

;; +-------------------------------------------------------------------------------------------------+
;; CONSTANTS

(define MAX-FISH-PER-TILE 5)
(define posint? (and/c integer? positive?))

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

;; make-board-with-holes : posint? posint? (listof posn?) natural? -> board?
;; Creates a board with 
(define (make-board-with-holes width height holes min-1s [max-fish MAX-FISH-PER-TILE])
  (define filtered-holes
    (filter (λ (hole) (posn-within-bounds? hole width height)) holes))
  (define num-tiles (- (* width height) (length filtered-holes)))
  
  ;; Error checking
  (when (< num-tiles min-1s)
    (raise-arguments-error 'make-board-with-holes
                           (~a  "Impossible to create a board with the specified holes "
                                "and min number of 1-fish tiles")
                           "width" width
                           "height" height
                           "holes" holes
                           "min-1s" min-1s))
  
  (define start-board (make-even-board width height 0))
  (define random-tiles (random-list-with-min-1s num-tiles min-1s max-fish))
  
  (for ([x width])
    (for ([y height]
          #:unless (member (make-posn x y) filtered-holes))
      (set-tile! (make-posn x y)
                 (first random-tiles)
                 start-board)
      (set! random-tiles (rest random-tiles))))
  start-board)

;; make-even-board : posint? posint? tile? -> board?
;; Create a game board of the given width and height filled with the given tile
(define (make-even-board width height tile)
  (build-vector width (λ (x) (make-vector height tile))))

;; remove-tile! : posn? board? -> board?
;; SIDE EFFECTS: board
;; Removes the tile at the given doubled position from the board
(define (remove-tile! posn board)
  (when (hole? (get-tile posn board))
    (raise-argument-error 'remove-tile! (~a posn " is already a hole and cannot be removed") 0))
  (set-tile! posn 0 board))

;; valid-movements : posn? board? -> (listof posn?)
;; Creates a list of valid movements on the board, starting from the top and moving clockwise
(define (valid-movements posn board)
  (when (not (posn-within-bounds? posn (board-columns board) (board-rows board)))
    (raise-argument-error 'valid-movements
                          (~a posn " not within the bounds of the given board")
                          0))
  (when (hole? (get-tile posn board))
    (raise-argument-error 'valid-movements
                          (~a posn " is a hole, no movements can be made from this tile")
                          0))

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

;; board-columns : board? -> posint?
;; Number of columns in the board
(define (board-columns board)
  (vector-length board))

;; board-rows : board? -> posint?
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
;; INVARIANT: length >= min-1s
;; Builds a list of tiles with no holes, a max size for each tile, and a minimum number of 1s
(define (random-list-with-min-1s length min-1s max-tile-size)
  (shuffle (append (build-list min-1s (λ (x) 1))
                   ;; add1 shifts the output range from [0, max-tile-size) to [1, max-tile-size]
                   (build-list (- length min-1s) (λ (x) (add1 (random max-tile-size)))))))

;; valid-movements-direction : posn? board? (posn? -> posn?) -> (listof posn?)
;; Creates a list of valid movements on the board in a given direction
(define (valid-movements-direction posn board mover)
  (define moved (mover posn))
  (if (and (posn-within-bounds? moved (board-columns board) (board-rows board))
           (not (hole? (get-tile moved board))))
      (cons moved (valid-movements-direction moved board mover))
      '()))

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

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)

  ;; Testing Helper Functions
  (define (board-to-flat-list board)
    (foldr append '() (vector->list (vector-map vector->list board))))
  
  ;; Provided Functions
  ;; make-board-with-holes
  (check-equal? (make-board-with-holes 1 1 '() 1) #(#(1)))
  (check-equal? (make-board-with-holes 1 1 (list (make-posn 0 0)) 0) #(#(0)))
  (check-equal? (make-board-with-holes 3 3 (list (make-posn 0 0)
                                                 (make-posn 0 2)
                                                 (make-posn 1 1)
                                                 (make-posn 2 1))
                                       5)
                #(#(0 1 0) #(1 0 1) #(1 0 1)))
  (check-equal? (board-columns (make-board-with-holes 10 9 '() 15)) 10)
  (check-equal? (board-rows (make-board-with-holes 10 9 '() 15)) 9)
  (check-equal?
   (count hole? (board-to-flat-list
                 (make-board-with-holes 10 10
                                        (list (make-posn 0 0) (make-posn 9 4) (make-posn 2 3)
                                              (make-posn 6 1) (make-posn 3 4) (make-posn 4 0)
                                              (make-posn 2 2) (make-posn 7 1) (make-posn 8 11))
                                        15)))
   8)
  (check-true (>= (count (λ (x) (= x 1)) (board-to-flat-list (make-board-with-holes 10 10 '() 15)))
                  15))
  (check-exn exn:fail? (λ () (make-board-with-holes 1 1 '() 2)))
  (check-exn exn:fail? (λ () (make-board-with-holes 3 3 (list (make-posn 1 1)) 9)))
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
                                             #(2 0)))))
  ;; valid-movements
  (check-equal? (valid-movements (make-posn 1 2) #(#(1 1 1 1 1) #(1 1 1 1 1)))
                (list (make-posn 1 0)
                      (make-posn 1 1)
                      (make-posn 1 3)
                      (make-posn 1 4)
                      (make-posn 0 3)
                      (make-posn 0 4)
                      (make-posn 0 1)
                      (make-posn 0 0)))
  (check-equal? (valid-movements (make-posn 0 2) #(#(1 1 1 1 1) #(1 1 1 1 1)))
                (list (make-posn 0 0)
                      (make-posn 0 1)
                      (make-posn 1 0)
                      (make-posn 0 3)
                      (make-posn 1 4)
                      (make-posn 0 4)))
  (check-equal? (valid-movements (make-posn 1 2) #(#(0 0 0 0 0) #(0 0 1 0 0)))
                '())
  (check-exn exn:fail? (λ () (valid-movements (make-posn 4 4)
                                              (make-even-board 3 3 1))))
  (check-exn exn:fail? (λ () (valid-movements (make-posn 0 0)
                                              #(#(0 1) #(1 1)))))
 
  ;; Internal Helper Functions
  ;; random-list-with-min-1s
  (check-equal? (random-list-with-min-1s 0 0 5) '())
  (check-equal? (random-list-with-min-1s 3 3 5) (list 1 1 1))
  (check-true (>= (count (λ (x) (= x 1)) (random-list-with-min-1s 10 3 5))
                  3))
  ;; top-hexagon-posn
  (check-equal? (top-hexagon-posn (make-posn 1 2))
                (make-posn 1 0))
  (check-equal? (top-hexagon-posn (make-posn 2 3))
                (make-posn 2 1))
  (check-equal? (top-hexagon-posn (make-posn 0 0))
                (make-posn 0 -2))
  ;; bottom-hexagon-posn
  (check-equal? (bottom-hexagon-posn (make-posn 1 2))
                (make-posn 1 4))
  (check-equal? (bottom-hexagon-posn (make-posn 2 3))
                (make-posn 2 5))
  (check-equal? (bottom-hexagon-posn (make-posn 0 0))
                (make-posn 0 2))
  ;; top-right-hexagon-posn
  (check-equal? (top-right-hexagon-posn (make-posn 1 2))
                (make-posn 1 1))
  (check-equal? (top-right-hexagon-posn (make-posn 2 3))
                (make-posn 3 2))
  (check-equal? (top-right-hexagon-posn (make-posn 0 0))
                (make-posn 0 -1))
  ;; bottom-right-hexagon-posn
  (check-equal? (bottom-right-hexagon-posn (make-posn 1 2))
                (make-posn 1 3))
  (check-equal? (bottom-right-hexagon-posn (make-posn 2 3))
                (make-posn 3 4))
  (check-equal? (bottom-right-hexagon-posn (make-posn 0 0))
                (make-posn 0 1))
  ;; top-left-hexagon-posn
  (check-equal? (top-left-hexagon-posn (make-posn 1 2))
                (make-posn 0 1))
  (check-equal? (top-left-hexagon-posn (make-posn 2 3))
                (make-posn 2 2))
  (check-equal? (top-left-hexagon-posn (make-posn 0 0))
                (make-posn -1 -1))
  ;; bottom-left-hexagon-posn
  (check-equal? (bottom-left-hexagon-posn (make-posn 1 2))
                (make-posn 0 3))
  (check-equal? (bottom-left-hexagon-posn (make-posn 2 3))
                (make-posn 2 4))
  (check-equal? (bottom-left-hexagon-posn (make-posn 0 0))
                (make-posn -1 1))
  ;; valid-movements-direction
  (check-equal? (valid-movements-direction (make-posn 0 0)
                                           #(#(1))
                                           top-hexagon-posn)
                '())
  (check-equal? (valid-movements-direction (make-posn 1 4)
                                           #(#(1 1 1 1 1)
                                             #(1 1 1 1 1))
                                           bottom-right-hexagon-posn)
                '())
  (check-equal? (valid-movements-direction (make-posn 1 4)
                                           #(#(1 2 3 4 1)
                                             #(1 0 1 0 1))
                                           top-right-hexagon-posn)
                '())
  (check-equal? (valid-movements-direction (make-posn 1 0)
                                           #(#(1 3 3 4 0)
                                             #(1 0 0 2 0))
                                           bottom-left-hexagon-posn)
                (list (make-posn 0 1) (make-posn 0 2)))
  (check-equal? (valid-movements-direction (make-posn 1 0)
                                           #(#(1 3 3 4 0)
                                             #(1 0 0 2 0))
                                           bottom-hexagon-posn)
                '())
  (check-equal? (valid-movements-direction (make-posn 0 0)
                                           #(#(1 3 3 4 0)
                                             #(1 0 0 2 0))
                                           bottom-hexagon-posn)
                (list (make-posn 0 2)))
  (check-equal? (valid-movements-direction (make-posn 0 1)
                                           #(#(1 3 3 4 0)
                                             #(1 0 0 2 0))
                                           top-left-hexagon-posn)
                (list (make-posn 0 0))))
