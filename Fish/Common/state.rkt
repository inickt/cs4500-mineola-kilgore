#lang racket/base

(require 2htdp/image
         lang/posn
         racket/bool
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
         (contract-out [can-any-move? (-> state? boolean?)])
         (contract-out [draw-state (-> state? natural? image?)])
         (contract-out [state-players (-> state? (non-empty-listof player?))]))

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct state [board players] #:transparent)
;; A GameState is a:
;; (make-state board? (non-empty-listof player?))
;; And represents a fish game state, containing:
;; - the current board state
;; - the players in the game
;; INVARIANT: state-players is an ordered list representing the turn order of the players. The length
;;            of the list is the number of players. The list order does not change.

(define-struct player [color score places] #:transparent)
;; A Player is a:
;; (make-player penguin? natural? (listof posn?))
;; And represents a player in a fish game, containing:
;; - the player's color
;; - the player's score in the game
;; - the player's penguin positions

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : (integer-in 2 4) board? -> state?
;; Create a game state with a given number of players and the given board.
;; Players are randomly assigned colors, and the turn order is set by the order of the player list.
(define (create-game num-players board)
  (make-state board (map (λ (color) (make-player color 0 '()))
                         (random-sample PENGUIN-COLORS num-players))))

;; place-penguin : penguin? posn? state? -> state?
;; Places a penguin on the board at the given position.
;; NOTE: Does not check number of penguins a player has placed. We think this should be
;;       handled by the game rules
(define (place-penguin penguin posn state)
  (when (not (member penguin (map player-color (state-players state))))
    (raise-arguments-error 'place-penguin
                           "The given penguin color is not in the game"
                           "penguin color" penguin))
  (when (not (valid-tile? posn (state-board state)))
    (raise-arguments-error 'place-penguin
                           "The given posn is either a hole or not on the board"
                           "posn" posn))
  (when (member posn (append-map player-places (state-players state)))
    (raise-arguments-error 'place-penguin
                           "There is already a penguin at the given position"
                           "posn" posn))
  (make-state (state-board state)
              (map (λ (player) (if (penguin=? (player-color player) penguin)
                                   (add-player-posn player posn)
                                   player))
                   (state-players state))))

;; move-penguin : penguin? posn? posn? state? -> state?
;; Moves the penguin from from-posn to to-posn, if the move is valid
(define (move-penguin penguin from-posn to-posn state)
  (when (not (valid-tile? from-posn (state-board state)))
    (raise-arguments-error 'move-penguin
                           "The given FROM position is not valid"
                           "from-posn" from-posn))
  (define player (findf (λ (player) (penguin=? (player-color player) penguin)) (state-players state)))
  (when (false? player)
    (raise-arguments-error 'move-penguin
                           "The given penguin does not exist in the game"
                           "penguin" penguin))
  (when (not (member from-posn (player-places player)))
    (raise-arguments-error 'move-penguin
                           "The given player does not have a penguin at the given FROM position"
                           "penguin" penguin
                           "from-posn" from-posn))
  (when (or (not (member to-posn (valid-movements from-posn (state-board state))))
            (member to-posn (append-map player-places (state-players state))))
    (raise-arguments-error 'move-penguin
                           "Moving from from-posn to to-posn is not a valid move"
                           "from-posn" from-posn
                           "to-posn" to-posn))
  (define points (get-tile from-posn (state-board state)))
  (make-state (remove-tile from-posn (state-board state))
              (map (λ (player) (if (penguin=? (player-color player) penguin)
                                   (update-player-posn player from-posn to-posn points)
                                   player))
                   (state-players state))))

;; can-any-move? : state? -> boolean?
;; Can any players in the game move?
(define (can-any-move? state)
  (define hole-board (penguins-to-holes state))
  ;; iterate over all player's penguins, checking each if they have any valid movements
  (ormap (λ (posn) (not (empty? (valid-movements posn hole-board))))
         (append-map player-places (state-players state))))

;; draw-state : state? natural? -> image?
;; Draws a game state at the given tile size
;; TODO: We probbaly want to give this a width instead of tile size
(define (draw-state state tile-size)
  (beside (draw-board-penguins (state-board state) (state-players state) tile-size)
          (draw-players (state-players state) tile-size)))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; update-player-posn : player? posn? posn? natural? -> player?
;; Adds points to the players score and replaces the given posn with a new posn
(define (update-player-posn player old-posn new-posn points)
  (make-player (player-color player)
               (+ (player-score player) points)
               (map (λ (posn) (if (equal? posn old-posn)
                                  new-posn
                                  posn))
                    (player-places player))))

;; add-player-posn : player? posn? -> player?
;; Adds a posn to a player's penguins
(define (add-player-posn player posn)
  (make-player (player-color player)
               (player-score player)
               (cons posn (player-places player))))

;; remove-player-posn : player? posn? -> player?
;; Removes a posn to a player's penguins
(define (remove-player-posn player posn)
  (make-player (player-color player)
               (player-score player)
               (remove posn (player-places player))))

;; penguins-to-holes : state? -> board?
;; removes the positions of the penguins from the board, replacing them with holes
(define (penguins-to-holes state)
  (define penguin-list (append-map player-places (state-players state)))
  (foldr remove-tile (state-board state) penguin-list))

;; draw-board-penguins : board? (listof player?) natural? -> image?
;; Draws the players' penguins on the given board
(define (draw-board-penguins board players tile-size)
  (define board-image (draw-board board tile-size))
  (define penguin-height (* 3/4 (tile-height tile-size)))
  (define convert-posn (λ (posn) (board-posn-to-pixel-posn posn tile-size)))
  (foldr (λ (player image)
           (define penguin-image (draw-penguin (player-color player) penguin-height))
           (place-images (make-list (length (player-places player)) penguin-image)
                         (map convert-posn (player-places player))
                         image))
         board-image
         players))

;; draw-players : (listof player?) -> image?
;; Draws a list of the given player colors in their turn order
(define (draw-players players size)
  (foldl (λ (player text-image)
           (above/align "left"
                        text-image
                        (text (string-titlecase (symbol->string (player-color player)))
                              size
                              (penguin-color-map (player-color player)))))
         (text "Players" (* 1.2 size) 'black)
         players))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)

  (define test-state
    (make-state '((1 2 0 1) (1 3 1 0) (5 5 0 2))
                (list (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1)))
                      (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                      (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3))))))
  
  ;; Provided Functions
  ;; create-game
  (check-equal? (state-board (create-game 2 (make-even-board 3 3 2)))
                (make-even-board 3 3 2))
  (check-equal? (state-board (create-game 4 (make-even-board 3 3 2)))
                (make-even-board 3 3 2))
  (check-equal? (length (state-players (create-game 2 (make-even-board 3 3 2))))
                2)
  (check-equal? (length (state-players (create-game 3 (make-even-board 3 3 2))))
                3)
  (check-equal? (length (state-players (create-game 4 (make-even-board 3 3 2))))
                4)
  (check-true (subset?
               (list->set (map player-color (state-players (create-game 4 (make-even-board 3 3 2)))))
               PENGUIN-COLORS))
  ;; place-penguin
  (check-equal? (place-penguin RED (make-posn 0 0) test-state)
                (make-state '((1 2 0 1) (1 3 1 0) (5 5 0 2))
                            (list (make-player RED 1 (list (make-posn 0 0)
                                                           (make-posn 0 1)
                                                           (make-posn 2 1)))
                                  (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                                  (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3))))))
  (check-exn exn:fail?
             (λ () (place-penguin BROWN (make-posn -1 0) test-state)))
  (check-exn exn:fail?
             (λ () (place-penguin RED (make-posn -1 0) test-state)))
  (check-exn exn:fail?
             (λ () (place-penguin RED (make-posn 2 2) test-state)))
  (check-exn exn:fail?
             (λ () (place-penguin RED (make-posn 1 1) test-state)))
  ;; move-penguin
  (check-equal? (move-penguin RED (make-posn 0 1) (make-posn 0 0) test-state)
                (make-state '((1 0 0 1) (1 3 1 0) (5 5 0 2))
                            (list (make-player RED 3 (list (make-posn 0 0) (make-posn 2 1)))
                                  (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                                  (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3))))))
  (check-equal? (move-penguin BLACK (make-posn 1 1) (make-posn 0 3) test-state)
                (make-state '((1 2 0 1) (1 0 1 0) (5 5 0 2))
                (list (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1)))
                      (make-player BLACK  3 (list (make-posn 1 0) (make-posn 0 3)))
                      (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3))))))
  (check-exn exn:fail?
             (λ () (move-penguin RED (make-posn 0 2) (make-posn 0 0) test-state)))
  (check-exn exn:fail?
             (λ () (move-penguin RED (make-posn 0 0) (make-posn 1 1) test-state)))
  (check-exn exn:fail?
             (λ () (move-penguin RED (make-posn 1 1) (make-posn 0 3) test-state)))
  (check-exn exn:fail?
             (λ () (move-penguin RED (make-posn 0 1) (make-posn 2 1) test-state)))
  ;; can-move?
  #|
  (check-false
   (can-move? RED (make-state-all-red 1 1 (list (make-posn 0 0)))))
  (check-true
   (can-move? RED (make-state-all-red 2 2 (list (make-posn 0 0)))))
  (check-false
   (can-move? RED (make-state-all-red 1 3 (list (make-posn 0 0)
                                                (make-posn 0 1)
                                                (make-posn 0 2)))))
  (check-false (can-move? RED test-state))
  (check-true (can-move? WHITE test-state))
  (check-false (can-move? BLACK test-state))
  (define can-move-test-state-2
    (make-state (remove-tile (make-posn 0 3) (state-board test-state))
                (state-players test-state)))
  (check-false (can-move? WHITE can-move-test-state-2))
  |#

  ;; Internal Helper Functions
  ;; add-penguin-posn
  #|
  (check-equal? (add-penguin-posn
                 (hash RED (list (make-posn 0 0))
                       WHITE (list (make-posn 1 1))
                       BROWN (list (make-posn 0 1)))
                 BLACK
                 (make-posn 1 0))
                (hash RED (list (make-posn 0 0))
                      WHITE (list (make-posn 1 1))
                      BROWN (list (make-posn 0 1))
                      BLACK (list (make-posn 1 0))))
  (check-equal? (add-penguin-posn
                 (hash RED (list (make-posn 2 4) (make-posn 0 3))
                       WHITE (list (make-posn 1 1) (make-posn 3 0))
                       BROWN (list (make-posn 0 1) (make-posn 3 3))
                       BLACK (list (make-posn 1 0) (make-posn 2 2)))
                 WHITE
                 (make-posn 1 3))
                (hash RED (list (make-posn 2 4) (make-posn 0 3))
                      WHITE (list (make-posn 1 3) (make-posn 1 1) (make-posn 3 0))
                      BROWN (list (make-posn 0 1) (make-posn 3 3))
                      BLACK (list (make-posn 1 0) (make-posn 2 2))))
  ;; remove-penguin-posn
  (check-equal? (remove-penguin-posn
                 (hash RED (list (make-posn 0 0))
                       WHITE (list (make-posn 1 1))
                       BROWN (list (make-posn 0 1)))
                 RED
                 (make-posn 0 0))
                (hash RED (list)
                      WHITE (list (make-posn 1 1))
                      BROWN (list (make-posn 0 1))))
  (check-equal? (remove-penguin-posn
                 (hash RED (list (make-posn 2 4) (make-posn 0 3))
                       WHITE (list (make-posn 1 1) (make-posn 3 0))
                       BROWN (list (make-posn 0 1) (make-posn 3 3))
                       BLACK (list (make-posn 1 0) (make-posn 2 2)))
                 WHITE
                 (make-posn 1 1))
                (hash RED (list (make-posn 2 4) (make-posn 0 3))
                      WHITE (list (make-posn 3 0))
                      BROWN (list (make-posn 0 1) (make-posn 3 3))
                      BLACK (list (make-posn 1 0) (make-posn 2 2))))
  |#
  ;; penguins-to-holes
  (check-equal? (penguins-to-holes test-state)
                '((1 0 0 1) (0 0 1 0) (0 0 0 0)))
  #;
  (check-equal? (penguins-to-holes
                 (make-state
                  '((1 1 1 1) (1 1 1 1) (1 1 1 1) (1 1 1 1) (1 1 1 1))
                  (make-player WHITE 0 (list (make-posn 1 0) (make-posn 1 1) (make-posn 1 2)))
                  (make-player BLACK 0 (list (make-posn 2 2) (make-posn 3 0) (make-posn 3 2)))
                  (make-player BROWN 0 (list (make-posn 3 3) (make-posn 4 3)))))
                '((1 1 1 1) (0 0 0 1) (1 1 0 1) (0 1 0 0) (1 1 1 0))))
