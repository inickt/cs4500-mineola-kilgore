#lang racket/base

(require lang/posn
         json
         racket/contract
         racket/format
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
  









  