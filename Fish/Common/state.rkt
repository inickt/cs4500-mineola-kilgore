#lang racket/base

(require 2htdp/image
         lang/posn
         racket/contract
         racket/format
         racket/list
         racket/math
         "board.rkt"
         "penguin.rkt")

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

;; TODO
;; - get players/order

(define-struct state [board penguins players])
(define penguins? (hash/c penguin? (listof posn?)))
;; A GameState is a:
;; (make-state board? penguins? (non-empty-listof penguin?))
;; And represents a fish game state, containing:
;; - the current board state
;; - the current positions of penguins on the board
;; - the current players and their penguin color the order of the players' turns, denoted by their color
;; INVARIANT: state-players is an ordered list, with the first being the first
;;            players turn, second being the turn after the first, and so on...

(define-struct player [color])
;; A Player is a (make-player penguin-color? natural?)
;; and represents a player in a fish game with their age in years, penguin color, and score

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

(define listof-2/3/4-natural? (or/c (list/c natural? natural?)
                                    (list/c natural? natural? natural?)
                                    (list/c natural? natural? natural? natural?)))

;; create-game : [2-4] board? -> state?
;; Create a game state with a given number of players and the given board
;; Players are created and randomly assigned colors, and the turn order TODO
(define (create-game num-players board)
  (make-state board #hash() (take (shuffle PENGUIN-COLORS) num-players)))

;; place-penguin : posn? state? -> state?
;; Places the current player's penguin on the board at the given position.
;; NOTE: Does not check number of penguins a player has placed. We think this should be
;;       handled by the game rules
(define (place-penguin posn state)
  (when (not (valid-tile? posn (state-board state)))
    (raise-argument-error 'place-penguin
                          (~a posn " is either a hole or not on the board")
                          0))
  (when (member posn (hash-values (state-penguins state)))
    (raise-argument-error 'place-penguin
                          (~a "There is already a penguin at " posn)
                          0))
  (make-state (state-board state)
              (add-penguin-posn (state-penguins state) (first (state-players state)) posn)
              (state-players state)))

;; move-pegnuin : penguin? posn? posn? state? -> state?
;;
#;
(define (move-penguin penguin from to state)
  ;; errors
  ;; is valid from posn? / is a penguin there?
  ;; is to posn in possible moves?
  
  ;; update posn
  ;; remove tile
  ...)

;; can-move? : penguin? state? -> boolean?
;; Can any of a player's penguins move?
#;
(define (can-move? player state)
  ;; turn penguins into holes
  ;; TODO: valid-movements remove need from not starting from a hole
  ;; iterate over all player's penguins, checking each if they have valid movements
  ;; build up valid moves, check if length is 0
  ...)

;; TODO draw players

;; draw-state : state? natural? -> image?
;; Draws a game state at the given width
(define (draw-state state width)
  (define tile-size 50)
  (define board-image (draw-board (state-board state) tile-size))
  (foldr (λ (pair image)
           (define pixel-posn (board-posn-to-pixel-posn (second pair) tile-size))
           (place-image (draw-penguin (first pair) 40)
                        (posn-x pixel-posn)
                        (posn-y pixel-posn)
                        image))
         board-image
         (hash->list (state-penguins state))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; penguins-per-player : state? -> natural?
;; Total numbers of penguins a player can have in a game 
(define (penguins-per-player state)
  (- 6 (+ (length (state-players state)))))

;; add-penguin-posn : penguins? penguin? posn?  -> penguins?
;; Adds the given position to the given penguin's positions
(define (add-penguin-posn penguin-posns penguin posn)
  (hash-update penguin-posns
               penguin
               (λ (posns) (cons posn posns))
               '()))

;; penguins-to-holes : state? -> board?
;; removes the positions of the penguins from the board, replacing them with holes
(define (penguins-to-holes state)
  (define penguin-list (foldr append '() (hash-values (state-penguins state))))
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
  ;; place-penguin
  

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
  ;; penguins-to-holes
  (check-equal? (penguins-to-holes
                 (make-state-all-red 3 3 (list (make-posn 0 0) (make-posn 1 2) (make-posn 2 2))))
                '((0 1 1) (1 1 0) (1 1 0)))
  (check-equal? (penguins-to-holes
                 (make-state-all-red 5 4 (list (make-posn 0 0)
                                               (make-posn 0 1)
                                               (make-posn 0 2)
                                               (make-posn 1 0)
                                               (make-posn 1 1)
                                               (make-posn 1 2)
                                               (make-posn 2 2)
                                               (make-posn 3 0)
                                               (make-posn 3 2)
                                               (make-posn 3 3)
                                               (make-posn 4 3))))
                '((0 0 0 1) (0 0 0 1) (1 1 0 1) (0 1 0 0) (1 1 1 0)))
   )
  