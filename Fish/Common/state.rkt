#lang racket/base

(require 2htdp/image
         lang/posn
         racket/contract
         racket/list
         racket/math
         racket/random
         racket/set
         "board.rkt"
         "penguin-color.rkt"
         "tile.rkt")

(provide (contract-out [state? (-> any/c boolean?)])
         (contract-out [make-state (-> board? (non-empty-listof player?) state?)])
         (contract-out [state-board (-> state? board?)])
         (contract-out [state-players (-> state? (non-empty-listof player?))])

         (contract-out [player? (-> any/c boolean?)])
         (contract-out [make-player (-> penguin-color? natural? (listof posn?) player?)])
         (contract-out [player-color (-> player? penguin-color?)])
         (contract-out [player-score (-> player? natural?)])
         (contract-out [player-places (-> player? (listof posn?))])

         (contract-out [move? (-> any/c boolean?)])
         (contract-out [make-move (-> posn? posn? move?)])
         (contract-out [move-to (-> move? posn?)])
         (contract-out [move-from (-> move? posn?)])

         (contract-out [create-state (-> (integer-in 2 4) board? state?)])
         (contract-out [place-penguin (-> state? posn? state?)])
         (contract-out [is-place-valid? (-> state? posn? boolean?)])
         (contract-out [move-penguin (-> state? move? state?)])
         (contract-out [is-move-valid? (-> state? move? boolean?)])
         (contract-out [skip-player (-> state? state?)])
         (contract-out [state-current-player (-> state? player?)])
         (contract-out [valid-moves (-> state? posn? (listof move?))])
         (contract-out [can-color-move? (-> state? penguin-color? boolean?)])
         (contract-out [can-any-move? (-> state? boolean?)])
         (contract-out [remove-penguins (-> state? penguin-color? state?)])
         (contract-out [draw-state (-> state? natural? image?)]))

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct state [board players] #:transparent)
;; A State is a (make-state board? (non-empty-listof player?))
;; And represents a snapshot of a game of Fish at some  point in time.
;; Actions that can be performed on a Fish State include placing a penguin at a non-hole Tile on the
;; board with no other penguin for the current player, and moving one of the current player's penguins
;; from one tile to another in a straight line without crossing a hole or another player's penguin.

;; A State contains:
;; - the current board
;; - the players in the game
;; INVARIANTS:
;; - state-players is an ordered list representing the turn order of the players. The length
;;   of the list is the number of players. The first in the list is the current player for
;;   the state, and will move to the end of the list after taking a turn.
;; - The positions of a player's penguines are unique, valid, and within the boundareis of the board
;; - Players have a unique color

(define-struct player [color score places] #:transparent)
;; A Player is a (make-player penguin-color? natural? (listof posn?))
;; And represents a player in a game of Fish. Each player is denoted by a unique color, and has some
;; number of penguins that they have placed on the board and can move on their turn. A player who's
;; penguins have no valid moves is considered stuck, and must be skipped.

; A Player contains:
;; - the player's color
;; - the player's score in the game
;; - the player's penguin positions
;; The coordinate system used for a player's penguins is an offset coordinate system, where each
;; of the player's positions is a valid tile on a board.

(define-struct move [from to] #:transparent)
;; A Move is a (make-move posn? posn?)
;; and represents a penguin's move on a fish board. Not all Moves are valid for a given Fish state:
;; validity is determined by both the from and to positions being on the Fish board, the current
;; player in the State having a penguin at from, and there being a direct line unblocked by a hole or
;; another player's penguin up from from and up to/including to.
;;
;; The coordinate system used for a move's from and to positions is an offset coordinate system, where
;; each of the positions is a valid tile on a board.

;; For visual examples of the coordinate system, see 'board.rkt'.

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-state : (integer-in 2 4) board? -> state?
;; Create a state with a given number of players and the given board.
;; Players are randomly assigned colors, and the turn order is set by the order of the player list.
(define (create-state num-players board)
  (make-state board (map (λ (color) (make-player color 0 '()))
                         (random-sample PENGUIN-COLORS num-players #:replacement? #f))))

;; place-penguin : state? posn? -> state?
;; Places a penguin on the board for the current player at the given position.
;; NOTES:
;; - Does not check number of penguins a player has placed
;; - The given position must be valid (checked with is-place-valid?)
(define (place-penguin state posn)
  (unless (is-place-valid? state posn)
    (raise-arguments-error 'place-penguin "The given placement is not valid" "posn" posn))
  (define players (state-players state))
  (make-state (state-board state)
              (rotate-players (cons (add-player-posn (first players) posn) (rest players)))))

;; is-place-valid? : state? posn? -> boolean?
;; Is it valid to place a penguin for the current player at the given position?
(define (is-place-valid? state posn)
  (and (valid-tile? posn (state-board state)) (not (any-penguin-at? state posn))))

;; move-penguin : state? move? -> state?
;; Applies a valid move to a penguin for the current player
;; NOTES:
;; - The current player is moved to the end of the turn order
;; - The current player's score increases by the amount of the tile they moved from
(define (move-penguin state move)
  (unless (is-move-valid? state move)
    (raise-arguments-error 'move-penguin "The given move is not valid" "move" move))

  (define from-posn (move-from move))
  (define players (state-players state))
  (define points (get-tile from-posn (state-board state)))
  (make-state
   (remove-tile from-posn (state-board state))
   (rotate-players (cons (update-player/move (first players) move points) (rest players)))))

;; is-move-valid? state? move? -> boolean?
;; Is it valid for the current player to perform the move?
(define (is-move-valid? state move)
  (and (current-player-has-penguin-at? state (move-from move))
       (list? (member move (valid-moves state (move-from move))))))

;; skip-player : state? -> state?
;; Skips the current player's turn
(define (skip-player state)
  (make-state (state-board state) (rotate-players (state-players state))))

;; state-current-player : state? -> player?
;; Gets the current player
(define (state-current-player state)
  (first (state-players state)))

;; valid-moves : state? posn? -> (listof move?)
;; Determines all legal moves from the given position
(define (valid-moves state from-posn)
  (unless (any-penguin-at? state from-posn)
    (raise-arguments-error 'valid-moves "There is no penguin at the given posn" "posn" from-posn))
  (map (λ (to-posn) (make-move from-posn to-posn))
       (valid-movements from-posn (penguins-to-holes state))))

;; can-color-move? : state? penguin-color? -> boolean?
;; Can the player with the given color move?
(define (can-color-move? state color)
  (ormap (λ (penguin) (cons? (valid-moves state penguin)))
         (player-places (findf (λ (player) (penguin-color=? (player-color player) color))
                               (state-players state)))))

;; can-any-move? : state? -> boolean?
;; Can any players in the game move?
(define (can-any-move? state)
  (define hole-board (penguins-to-holes state))
  (ormap (λ (posn) (cons? (valid-movements posn hole-board)))
         (append-map player-places (state-players state))))

;; remove-penguins : state? penguin-color? -> state?
;; Remove the given player's penguins
(define (remove-penguins state color)
  (make-state (state-board state)
               (map (λ (player) (if (penguin-color=? (player-color player) color)
                                    (make-player color (player-score player) '())
                                    player))
                    (state-players state))))

;; draw-state : state? natural? -> image?
;; Draws a game state at the given tile size
;; TODO: We probbaly want to give this a width instead of tile size
(define (draw-state state tile-size)
  (beside (draw-board-penguins (state-board state) (state-players state) tile-size)
          (draw-players (state-players state) tile-size)))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; rotate-players : (non-empty-list-of player?) -> (non-empty-list-of player?)
;; Moves the first player to the end of the player list
(define (rotate-players players)
  (append (rest players) (list (first players))))

;; any-penguin-at? : state? posn? -> boolean?
;; Is there any penguin at the given posn?
(define (any-penguin-at? state posn)
  (list? (member posn (append-map player-places (state-players state)))))

;; current-player-has-penguin-at? : state? posn? -> boolean?
;; Does the current player have a penguin at the given position?
(define (current-player-has-penguin-at? state posn)
  (list? (member posn (player-places (state-current-player state)))))

;; update-player/move : player? move? natural? -> player?
;; Adds points to the players score and applies the move
;; NOTE: Does not check if the player has a penguin at the move.
(define (update-player/move player move points)
  (make-player (player-color player)
               (+ (player-score player) points)
               (map (λ (posn) (if (equal? posn (move-from move)) (move-to move) posn))
                    (player-places player))))

;; add-player-posn : player? posn? -> player?
;; Adds a position to a player's places.
;; NOTE: Does not check if the player already has a penguin at the given position
(define (add-player-posn player posn)
  (make-player (player-color player) (player-score player) (cons posn (player-places player))))

;; penguins-to-holes : state? -> board?
;; Removes the positions of the penguins from the board, replacing them with holes
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
                        (text (string-append (describe-penguin (player-color player))
                                             " - "
                                             (number->string (player-score player)))
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
  ;; +--- create-state ---+
  (check-equal? (state-board (create-state 2 (make-even-board 3 3 2)))
                (make-even-board 3 3 2))
  (check-equal? (state-board (create-state 4 (make-even-board 3 3 2)))
                (make-even-board 3 3 2))
  (check-equal? (length (state-players (create-state 2 (make-even-board 3 3 2))))
                2)
  (check-equal? (length (state-players (create-state 3 (make-even-board 3 3 2))))
                3)
  (check-equal? (length (state-players (create-state 4 (make-even-board 3 3 2))))
                4)
  (check-true (subset?
               (list->set (map player-color (state-players (create-state 4 (make-even-board 3 3 2)))))
               PENGUIN-COLORS))
  ;; +--- place-penguin ---+
  (check-equal? (place-penguin test-state (make-posn 0 0))
                (make-state '((1 2 0 1) (1 3 1 0) (5 5 0 2))
                            (list (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                                  (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3)))
                                  (make-player RED 1 (list (make-posn 0 0)
                                                           (make-posn 0 1)
                                                           (make-posn 2 1))))))
  (check-exn exn:fail? (λ () (place-penguin test-state (make-posn 2 0))))
  (check-exn exn:fail? (λ () (place-penguin test-state (make-posn 0 2))))
  (check-exn exn:fail? (λ () (place-penguin test-state (make-posn -2 0))))
  ;; +--- is-place-valid? ---+
  (check-true (is-place-valid? test-state (make-posn 0 0)))
  (check-false (is-place-valid? test-state (make-posn -1 0)))
  (check-false (is-place-valid? test-state (make-posn 2 0)))
  ;; +--- move-penguin ---+
  (check-equal? (move-penguin test-state (make-move (make-posn 0 1) (make-posn 0 0)))
                (make-state '((1 0 0 1) (1 3 1 0) (5 5 0 2))
                            (list (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                                  (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3)))
                                  (make-player RED 3 (list (make-posn 0 0) (make-posn 2 1))))))
  (check-equal? (move-penguin (skip-player test-state) (make-move (make-posn 1 1) (make-posn 0 3)))
                (make-state '((1 2 0 1) (1 0 1 0) (5 5 0 2))
                            (list (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3)))
                                  (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1)))
                                  (make-player BLACK  3 (list (make-posn 1 0) (make-posn 0 3))))))
  ; from not valid
  (check-exn exn:fail?
             (λ () (move-penguin test-state (make-move (make-posn 0 2) (make-posn 0 0)))))
  ; penguin isn't at from posn
  (check-exn exn:fail?
             (λ () (move-penguin test-state (make-move (make-posn 0 0) (make-posn 1 1)))))
  ; invalid move
  (check-exn exn:fail?
             (λ () (move-penguin test-state (make-move (make-posn 0 1) (make-posn 2 1)))))
  ;; +--- is-move-valid? ---+
  (check-true (is-move-valid? test-state (make-move (make-posn 0 1) (make-posn 0 0))))
  (check-false (is-move-valid? test-state (make-move (make-posn 0 2) (make-posn 0 0))))
  (check-false (is-move-valid? test-state (make-move (make-posn 0 0) (make-posn 1 1))))
  (check-false (is-move-valid? test-state (make-move (make-posn 0 1) (make-posn 2 1))))
  ;; +--- skip-player ---+
  (check-equal? (skip-player test-state)
                (make-state (state-board test-state)
                            (list (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                                  (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3)))
                                  (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1))))))
  ;; +--- state-current-player ---+
  (check-equal? (state-current-player test-state)
                (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1))))
  ;; +--- valid-moves ---+
  (check-equal? (valid-moves test-state (make-posn 0 1))
                (list (make-move (make-posn 0 1) (make-posn 1 2))
                      (make-move (make-posn 0 1) (make-posn 0 3))
                      (make-move (make-posn 0 1) (make-posn 0 0))))
  (check-equal? (valid-moves test-state (make-posn 1 0))
                (list (make-move (make-posn 1 0) (make-posn 1 2))))
  (check-equal? (valid-moves test-state (make-posn 1 1))
                (list (make-move (make-posn 1 1) (make-posn 1 2))
                      (make-move (make-posn 1 1) (make-posn 0 3))))
  (check-equal? (valid-moves test-state (make-posn 2 1)) '())
  (check-exn exn:fail? (λ () (valid-moves test-state (make-posn -1 0))))
  (check-exn exn:fail? (λ () (valid-moves test-state (make-posn 0 2))))
  (check-exn exn:fail? (λ () (valid-moves test-state (make-posn 0 0))))
  ;; +--- can-color-move? ---+
  (check-true (can-color-move? test-state BLACK))
  (check-true (can-color-move? test-state RED))
  (check-false (can-color-move? test-state WHITE))
  ;; +--- can-any-move? ---+
  (check-false (can-any-move? (create-state 2 (make-even-board 3 3 2))))
  (check-true (can-any-move? test-state))
  (define can-move-test-state
    (make-state (remove-tile (make-posn 0 0)
                             (remove-tile (make-posn 1 2)
                                          (remove-tile (make-posn 0 3)
                                                       (state-board test-state))))
                (state-players test-state)))
  (check-false (can-any-move? can-move-test-state))
  ;; +--- draw-state ---+
  ;; TODO
  
  ;; Internal Helper Functions
  ;; +--- rotate-players ---+
  (check-equal? (rotate-players (list (make-player BLACK 0 '())
                                      (make-player WHITE 1 '())
                                      (make-player RED 2 '())))
                (list (make-player WHITE 1 '())
                      (make-player RED 2 '())
                      (make-player BLACK 0 '())))
  ;; +--- any-penguin-at? ---+
  (check-true (any-penguin-at? test-state (make-posn 2 3)))
  (check-false (any-penguin-at? test-state (make-posn 1 3)))
  ;; +--- current-player-has-penguin-at? ---+
  (check-true (current-player-has-penguin-at? test-state (make-posn 2 1)))
  (check-false (current-player-has-penguin-at? test-state (make-posn 2 3)))
  (check-false (current-player-has-penguin-at? test-state (make-posn 0 3)))
  ;; +--- update-player/move ---+
  (check-equal? (update-player/move (make-player RED 10 (list (make-posn 2 2)))
                                    (make-move (make-posn 2 2) (make-posn 1 1))
                                    5)
                (make-player RED 15 (list (make-posn 1 1))))
  (check-equal? (update-player/move (make-player RED 10 (list (make-posn 1 1)
                                                              (make-posn 3 3)
                                                              (make-posn 2 2)))
                                    (make-move (make-posn 3 3) (make-posn 1 2))
                                    10)
                (make-player RED 20 (list (make-posn 1 1)
                                          (make-posn 1 2)
                                          (make-posn 2 2))))
  ;; +--- add-player-posn ---+
  (check-equal? (add-player-posn (make-player RED 10 (list (make-posn 2 2)))
                                 (make-posn 1 1))
                (make-player RED 10 (list (make-posn 1 1) (make-posn 2 2))))
  (check-equal? (add-player-posn (make-player RED 10 '())
                                 (make-posn 2 2))
                (make-player RED 10 (list (make-posn 2 2))))
  ;; +--- penguins-to-holes ---+
  (check-equal? (penguins-to-holes test-state)
                '((1 0 0 1) (0 0 1 0) (0 0 0 0)))
  (check-equal? (penguins-to-holes
                 (make-state
                  '((1 1 1 1) (1 1 1 1) (1 1 1 1) (1 1 1 1) (1 1 1 1))
                  (list
                   (make-player WHITE 0 (list (make-posn 1 0) (make-posn 1 1) (make-posn 1 2)))
                   (make-player BLACK 0 (list (make-posn 2 2) (make-posn 3 0) (make-posn 3 2)))
                   (make-player BROWN 0 (list (make-posn 3 3) (make-posn 4 3))))))
                '((1 1 1 1) (0 0 0 1) (1 1 0 1) (0 1 0 0) (1 1 1 0)))
  ;; +--- draw-board-penguins ---+
  ;; TODO
  ;; +--- draw-players ---+
  ;; TODO
  )
