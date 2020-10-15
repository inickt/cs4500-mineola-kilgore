#lang racket/base

(require 2htdp/image
         lang/posn
         racket/contract
         racket/format
         racket/list
         racket/math
         racket/random
         racket/set
         "board.rkt"
         "penguin.rkt"
         "tile.rkt")

(provide (contract-out [create-game (-> (integer-in 2 4) board? state?)])
         (contract-out [place-penguin (-> penguin? posn? state? state?)])
         (contract-out [move-penguin (-> penguin? posn? posn? state? state?)])
         (contract-out [can-move? (-> penguin? state? boolean?)])
         (contract-out [draw-state (-> state? natural? image?)])
         (contract-out [state-players (-> state? (listof penguin?))]))

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct state [board penguins players])
(define penguins? (hash/c penguin? (listof posn?)))
;; A GameState is a:
;; (make-state board? penguins? (non-empty-listof penguin?))
;; And represents a fish game state, containing:
;; - the current board state
;; - the current positions of penguins on the board
;; - the player's penguin colors
;; INVARIANT: state-players is an ordered list representing the turn order of the players. The length
;;            of the list is the number of players. The list order does not change.

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : (integer-in 2 4) board? -> state?
;; Create a game state with a given number of players and the given board.
;; Players are randomly assigned colors, and the turn order is set by the order of the player list.
;; TODO: tests
(define (create-game num-players board)
  (make-state board #hash() (random-sample PENGUIN-COLORS num-players)))

;; place-penguin : penguin? posn? state? -> state?
;; Places a penguin on the board at the given position.
;; NOTE: Does not check number of penguins a player has placed. We think this should be
;;       handled by the game rules
;; TODO: tests
(define (place-penguin penguin posn state)
  (when (not (valid-tile? posn (state-board state)))
    (raise-argument-error 'place-penguin
                          (~a posn " is either a hole or not on the board")
                          0))
  (when (member posn (hash-values (state-penguins state)))
    (raise-argument-error 'place-penguin
                          (~a "There is already a penguin at " posn)
                          0))
  (make-state (state-board state)
              (add-penguin-posn (state-penguins state) penguin posn)
              (state-players state)))

;; move-penguin : penguin? posn? posn? state? -> state?
;; Moves the penguin from from-posn to to-posn, if the move is valid
(define (move-penguin penguin from-posn to-posn state)
  (when (not (valid-tile? from-posn (state-board state)))
    (raise-arguments-error 'move-penguin
                           "The selected FROM position is not valid"
                           "from-posn" from-posn))
  (when (boolean? (hash-ref (state-penguins state) penguin #f))
    (raise-arguments-error 'move-penguin
                           "The selected FROM position does not have a penguin"
                           "from-posn" from-posn))
  (when (or (not (member to-posn (valid-movements from-posn (state-board state))))
            (member to-posn (apply append (hash-values (state-penguins state)))))
    (raise-arguments-error 'move-penguin
                           "Moving from from-posn to to-posn is not a valid move"
                           "from-posn" from-posn
                           "to-posn" to-posn))
  
  (make-state (remove-tile from-posn (state-board state))
              (add-penguin-posn
               (remove-penguin-posn (state-penguins state) penguin from-posn)
               penguin to-posn)
              (state-players state)))

;; can-move? : penguin? state? -> boolean?
;; Can any of a player's penguins move?
(define (can-move? player state)
  (define hole-board (penguins-to-holes state))
  ;; iterate over all player's penguins, checking each if they have any valid movements
  (ormap (λ (penguin) (not (empty? (valid-movements penguin hole-board))))
         (hash-ref (state-penguins state) player)))

;; draw-state : state? natural? -> image?
;; Draws a game state at the given tile size
;; TODO: use width instead of tile size, draw players
(define (draw-state state tile-size)
  (define board-image (draw-board (state-board state) tile-size))
  (define penguin-height (* 3/4 (tile-height tile-size)))
  (define convert-posn (λ (posn) (board-posn-to-pixel-posn posn tile-size)))
  (for/fold ([image board-image])
            ([(penguin posns) (in-hash (state-penguins state))])
    (define penguin-image (draw-penguin penguin penguin-height))
    (place-images (make-list (length posns) penguin-image)
                  (map convert-posn posns)
                  image)))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; add-penguin-posn : penguins? penguin? posn?  -> penguins?
;; Adds the given position to the given penguin's positions
(define (add-penguin-posn penguin-posns penguin posn)
  (hash-update penguin-posns
               penguin
               (λ (posns) (cons posn posns))
               '()))

;; remove-penguin-posn : penguins? penguin? posn?  -> penguins?
;; Removes the given position from the given penguin's positions
(define (remove-penguin-posn penguin-posns penguin posn)
  (hash-update penguin-posns
               penguin
               (λ (posns) (remove posn posns))
               '()))

;; penguins-to-holes : state? -> board?
;; removes the positions of the penguins from the board, replacing them with holes
(define (penguins-to-holes state)
  (define penguin-list (apply append (hash-values (state-penguins state))))
  (foldr remove-tile (state-board state) penguin-list))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)
  ;; Testing Helpers
  (define (make-state-all-red w h lo-penguins)
    (make-state (make-even-board w h 1)
                (foldr
                 (λ (penguin hash) (hash-update hash 'red (λ (x) (cons penguin x)) '()))
                 #hash()
                 lo-penguins)
                '(red)))
  
  ;; Provided Functions
  ;; place-penguin (penguin from to state) (error on invalid from, no penguin on from, invalid move)
  (define move-penguin-test-state
    (make-state '((1 1 1 1) (1 1 1 1) (1 1 1 1))
                (hash-set
                 (hash-set
                  (hash-set #hash() 'red (list (make-posn 0 0) (make-posn 0 1) (make-posn 2 1)))
                  'black (list (make-posn 1 0) (make-posn 1 2)))
                 'white (list (make-posn 2 0) (make-posn 2 3)))
                '(red white black)))
  #;
  (check-equal? (move-penguin )
                ...)

  ;; create-game
  (check-equal? (state-board (create-game 2 (make-even-board 3 3 2)))
                (make-even-board 3 3 2))
  (check-equal? (state-board (create-game 4 (make-even-board 3 3 2)))
                (make-even-board 3 3 2))
  (check-equal? (state-penguins (create-game 3 (make-even-board 3 3 2)))
                #hash())
  (check-equal? (length (state-players (create-game 2 (make-even-board 3 3 2))))
                2)
  (check-equal? (length (state-players (create-game 3 (make-even-board 3 3 2))))
                3)
  (check-equal? (length (state-players (create-game 4 (make-even-board 3 3 2))))
                4)
  (check-true (subset? (list->set (state-players (create-game 4 (make-even-board 3 3 2))))
                      PENGUIN-COLORS))

  
  ;; can-move?
  (check-equal?
   (can-move? 'red (make-state-all-red 1 1 (list (make-posn 0 0))))
   #f)
  (check-equal?
   (can-move? 'red (make-state-all-red 2 2 (list (make-posn 0 0))))
   #t)
  (check-equal?
   (can-move? 'red (make-state-all-red 1 3 (list (make-posn 0 0)
                                                 (make-posn 0 1)
                                                 (make-posn 0 2))))
   #f)
  (define can-move-test-state (make-state '((1 1 1 1) (1 0 0 0))
                                          (hash-set
                                           (hash-set
                                            (hash-set #hash() 'red (list (make-posn 0 0)))
                                            'white (list (make-posn 0 1) (make-posn 0 2)))
                                           'black (list (make-posn 1 0)))
                                          '(red black white)))
  (check-false (can-move? 'red can-move-test-state))
  (check-true (can-move? 'white can-move-test-state))
  (check-false (can-move? 'black can-move-test-state))
  (define can-move-test-state-2
    (make-state (remove-tile (make-posn 0 3) (state-board can-move-test-state))
                (state-penguins can-move-test-state)
                (state-players can-move-test-state)))
  (check-false (can-move? 'white can-move-test-state-2))

  ;; Internal Helper Functions
  ;; penguins-per-player

  ;; add-penguin-posn
  (check-equal? (add-penguin-posn
                 (hash 'RED (list (make-posn 0 0))
                       'WHITE (list (make-posn 1 1))
                       'BROWN (list (make-posn 0 1)))
                 'BLACK
                 (make-posn 1 0))
                (hash 'RED (list (make-posn 0 0))
                      'WHITE (list (make-posn 1 1))
                      'BROWN (list (make-posn 0 1))
                      'BLACK (list (make-posn 1 0))))
  (check-equal? (add-penguin-posn
                 (hash 'RED (list (make-posn 2 4) (make-posn 0 3))
                       'WHITE (list (make-posn 1 1) (make-posn 3 0))
                       'BROWN (list (make-posn 0 1) (make-posn 3 3))
                       'BLACK (list (make-posn 1 0) (make-posn 2 2)))
                 'WHITE
                 (make-posn 1 3))
                (hash 'RED (list (make-posn 2 4) (make-posn 0 3))
                      'WHITE (list (make-posn 1 3) (make-posn 1 1) (make-posn 3 0))
                      'BROWN (list (make-posn 0 1) (make-posn 3 3))
                      'BLACK (list (make-posn 1 0) (make-posn 2 2))))
  ;; remove-penguin-posn
  (check-equal? (remove-penguin-posn
                 (hash 'RED (list (make-posn 0 0))
                       'WHITE (list (make-posn 1 1))
                       'BROWN (list (make-posn 0 1)))
                 'RED
                 (make-posn 0 0))
                (hash 'RED (list)
                      'WHITE (list (make-posn 1 1))
                      'BROWN (list (make-posn 0 1))))
  (check-equal? (remove-penguin-posn
                 (hash 'RED (list (make-posn 2 4) (make-posn 0 3))
                       'WHITE (list (make-posn 1 1) (make-posn 3 0))
                       'BROWN (list (make-posn 0 1) (make-posn 3 3))
                       'BLACK (list (make-posn 1 0) (make-posn 2 2)))
                 'WHITE
                 (make-posn 1 1))
                (hash 'RED (list (make-posn 2 4) (make-posn 0 3))
                      'WHITE (list (make-posn 3 0))
                      'BROWN (list (make-posn 0 1) (make-posn 3 3))
                      'BLACK (list (make-posn 1 0) (make-posn 2 2))))
  ;; penguins-to-holes
  (check-equal? (penguins-to-holes
                 (make-state-all-red 3 3 (list (make-posn 0 0) (make-posn 1 2) (make-posn 2 2))))
                '((0 1 1) (1 1 0) (1 1 0)))
  (check-equal? (penguins-to-holes
                 (make-state-all-red 5 4 (list (make-posn 0 0) (make-posn 0 1) (make-posn 0 2)
                                               (make-posn 1 0) (make-posn 1 1) (make-posn 1 2)
                                               (make-posn 2 2) (make-posn 3 0) (make-posn 3 2)
                                               (make-posn 3 3) (make-posn 4 3))))
                '((0 0 0 1) (0 0 0 1) (1 1 0 1) (0 1 0 0) (1 1 1 0))))
