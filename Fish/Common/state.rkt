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
         "penguin-color.rkt"
         "tile.rkt")

(provide (contract-out [create-game (-> (integer-in 2 4) board? state?)])
         (contract-out [place-penguin (-> penguin-color? posn? state? state?)])
         (contract-out [move-penguin (-> penguin-color? posn? posn? state? state?)])
         (contract-out [can-any-move? (-> state? boolean?)])
         (contract-out [can-color-move? (-> penguin-color? state? boolean?)])
         (contract-out [draw-state (-> state? natural? image?)])
         (contract-out [state? (-> any/c boolean?)])
         (contract-out [make-state (-> board? (non-empty-listof player?) state?)])
         (contract-out [state-board (-> state? board?)])
         (contract-out [state-players (-> state? (non-empty-listof player?))])
         (contract-out [make-player (-> penguin-color? natural? (listof posn?) player?)])
         (contract-out [player-color (-> player? penguin-color?)])
         (contract-out [player-score (-> player? natural?)])
         (contract-out [player-places (-> player? (listof posn?))])
         (contract-out [is-place-valid? (-> penguin-color? posn? state? boolean?)])
         (contract-out [is-move-valid? (-> penguin-color? posn? posn? state? boolean?)])
         (contract-out [valid-moves (-> posn? state? (listof posn?))])
         (contract-out [get-player (-> penguin-color? state? player?)])
         (contract-out [finalize-state (-> state? state?)])
         (contract-out [remove-player-penguins (-> state? penguin-color? state?)]))

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct state [board players] #:transparent)
;; A State is a:
;; (make-state board? (non-empty-listof player?))
;; And represents a fish game state, containing:
;; - the current board state
;; - the players in the game
;; INVARIANT: state-players is an ordered list representing the turn order of the players. The length
;;            of the list is the number of players. The list order does not change.

(define-struct player [color score places] #:transparent)
;; A Player is a:
;; (make-player penguin-color? natural? (listof posn?))
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

;; place-penguin : penguin-color? posn? state? -> state?
;; Places a penguin on the board at the given position.
;; NOTE: Does not check number of penguins a player has placed. We think this should be
;;       handled by the game rules
(define (place-penguin color posn state)
  (when (not (penguin-color-exists? color state))
    (raise-arguments-error 'place-penguin
                           "The given penguin color is not in the game"
                           "penguin color" color))
  (when (not (valid-tile? posn (state-board state)))
    (raise-arguments-error 'place-penguin
                           "The given posn is either a hole or not on the board"
                           "posn" posn))
  (when (penguin-at? posn state)
    (raise-arguments-error 'place-penguin
                           "There is already a penguin at the given position"
                           "posn" posn))
  (make-state (state-board state)
              (map (λ (player) (if (penguin-color=? (player-color player) color)
                                   (add-player-posn player posn)
                                   player))
                   (state-players state))))

;; move-penguin : penguin-color? posn? posn? state? -> state?
;; Moves the penguin from from-posn to to-posn, if the move is valid
(define (move-penguin color from-posn to-posn state)
  (when (not (valid-tile? from-posn (state-board state)))
    (raise-arguments-error 'move-penguin
                           "The given FROM position is not valid"
                           "from-posn" from-posn))
  (when (not (penguin-color-exists? color state))
    (raise-arguments-error 'move-penguin
                           "The given penguin color does not exist in the game"
                           "penguin color" color))
  (when (not (player-has-penguin-at? color from-posn state))
    (raise-arguments-error 'move-penguin
                           "The given color does not have a penguin at the given FROM position"
                           "penguin color" color
                           "from-posn" from-posn))
  (when (not (move-is-valid? from-posn to-posn state))
    (raise-arguments-error 'move-penguin
                           "Moving from from-posn to to-posn is not a valid move"
                           "from-posn" from-posn
                           "to-posn" to-posn))
  (define points (get-tile from-posn (state-board state)))
  (make-state (remove-tile from-posn (state-board state))
              (map (λ (player) (if (penguin-color=? (player-color player) color)
                                   (update-player-posn player from-posn to-posn points)
                                   player))
                   (state-players state))))

;; valid-moves : posn? state? -> (listof posn?)
;; Determines all positions resulting in a legal move from the given posn
(define (valid-moves posn state)
  (when (not (valid-tile? posn (state-board state)))
    (raise-arguments-error 'valid-moves
                           "The specified posn is not valid"
                           "posn" posn))
  (when (not (penguin-at? posn state))
    (raise-arguments-error 'valid-moves
                           "There is no penguin at the given posn"
                           "posn" posn))
  (valid-movements posn (penguins-to-holes state)))

;; can-color-move? : penguin-color? state? -> boolean?
;; Can the player with the given color move?
(define (can-color-move? color state)
  (ormap (λ (posn) (cons? (valid-moves posn state)))
         (player-places (get-player color state))))

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

;; is-place-valid? : penguin-color? posn? state? -> boolean?
;; Is it valid to place a penguin with the given color at the given posn?
(define (is-place-valid? color posn state)
  (and (valid-tile? posn (state-board state))
       (penguin-color-exists? color state)
       (not (penguin-at? posn state))))

;; is-move-valid? : penguin-color? posn? posn? state? -> boolean?
;; Is it valid to move a penguin of the given color from from-posn to to-posn?
(define (is-move-valid? color from-posn to-posn state)
  (and (valid-tile? from-posn (state-board state))
       (player-has-penguin-at? color from-posn state)
       (is-place-valid? color to-posn state)
       (move-is-valid? from-posn to-posn state)))

;; get-player : penguin-color? state? -> player?
;; Gets the player with the given penguin color
(define (get-player color state)
  (define pl (findf (λ (player) (penguin-color=? color (player-color player))) (state-players state)))
  (when (false? pl) (raise-arguments-error 'get-player
                                           "The given player color is not in the state"
                                           "color" color))
  pl)

;; finalize-state : state? -> state?
;; Removes all penguins, adding the values of the tiles the penguins were on to their players' scores
;; scores appropriately.
(define (finalize-state end-state)
  (make-state (penguins-to-holes end-state)
              (map (λ (player) (finalize-player player (state-board end-state)))
                   (state-players end-state))))

;; remove-player-penguins : state? penguin-color? -> player?
;; Removes all penguins of the given color
(define (remove-player-penguins state color)
  (when (not (member color (map player-color (state-players state))))
    (raise-arguments-error 'remove-player "The given color is not in the game" "color" color))
  (make-state (state-board state)
              (map (λ (player) (if (penguin-color=? (player-color player) color)
                                   (make-player (player-color player) (player-score player) '())
                                   player))
                      (state-players state))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; penguin-color-exists? : penguin-color? state? -> boolean?
;; Is the pengin color in the game?
(define (penguin-color-exists? color state)
  (list? (member color (map player-color (state-players state)))))

;; penguin-at? : posn? state? -> boolean?
;; Is there a penguin at the given posn?
(define (penguin-at? posn state)
  (list? (member posn (append-map player-places (state-players state)))))

;; player-has-penguin-at? : penguin-color? posn? state? -> boolean?
;; Does the penguin color have a penguin at the posn?
(define (player-has-penguin-at? color posn state)
  (and (penguin-color-exists? color state)
       (list? (member posn
                      (player-places (findf (λ (player) (penguin-color=? color (player-color player)))
                                            (state-players state)))))))

;; move-is-valid? : posn? posn? state? -> boolean?
;; Is the move valid?
(define (move-is-valid? from-posn to-posn state)
  (or (list? (member to-posn (valid-movements from-posn (state-board state))))
      (not (list? (member to-posn (append-map player-places (state-players state)))))))

;; update-player-posn : player? posn? posn? natural? -> player?
;; Adds points to the players score and replaces the given posn with a new posn.
;; Does not check if the player has the given posn.
(define (update-player-posn player old-posn new-posn points)
  (make-player (player-color player)
               (+ (player-score player) points)
               (map (λ (posn) (if (equal? posn old-posn)
                                  new-posn
                                  posn))
                    (player-places player))))

;; add-player-posn : player? posn? -> player?
;; Adds a posn to a player's penguins. Does not check if the player already has the given posn.
(define (add-player-posn player posn)
  (make-player (player-color player)
               (player-score player)
               (cons posn (player-places player))))

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
                        (text (string-append (describe-penguin (player-color player))
                                             " - "
                                             (number->string (player-score player)))
                              size
                              (penguin-color-map (player-color player)))))
         (text "Players" (* 1.2 size) 'black)
         players))

;; finalize-player : player? board? -> player?
;; Adds the score of the tiles a player's penguins are on, and removes all of their penguins
(define (finalize-player player board)
  (make-player
   (player-color player)
   (foldr (λ (posn score-acc) (+ score-acc (get-tile posn board)))
          (player-score player)
          (player-places player))
   '()))

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
  ; from not valid
  (check-exn exn:fail?
             (λ () (move-penguin RED (make-posn 0 2) (make-posn 0 0) test-state)))
  ; penguin isn't at from posn
  (check-exn exn:fail?
             (λ () (move-penguin RED (make-posn 0 0) (make-posn 1 1) test-state)))
  ; player doesn't exist
  (check-exn exn:fail?
             (λ () (move-penguin BROWN (make-posn 0 1) (make-posn 0 0) test-state)))
  ; invalid move
  (check-exn exn:fail?
             (λ () (move-penguin RED (make-posn 0 1) (make-posn 2 1) test-state)))
  ;; can-color-move?
  (check-true (can-color-move? RED test-state))
  (check-true (can-color-move? BLACK test-state))
  (check-false (can-color-move? WHITE test-state))
  ;; can-any-move?
  (check-false (can-any-move? (create-game 2 (make-even-board 3 3 2))))
  (check-true (can-any-move? test-state))
  (define can-move-test-state
    (make-state (remove-tile (make-posn 0 0)
                             (remove-tile (make-posn 1 2)
                                          (remove-tile (make-posn 0 3)
                                                       (state-board test-state))))
                (state-players test-state)))
  (check-false (can-any-move? can-move-test-state))
  ;; is-place-valid?
  (check-true (is-place-valid? RED (make-posn 0 0) test-state))
  (check-false (is-place-valid? BROWN (make-posn 0 0) test-state))
  (check-false (is-place-valid? WHITE (make-posn -1 0) test-state))
  (check-false (is-place-valid? WHITE (make-posn 2 0) test-state))
  ;; is-move-valid?
  (check-true (is-move-valid? RED (make-posn 0 1) (make-posn 0 0) test-state))
  (check-false (is-move-valid? RED (make-posn 0 2) (make-posn 0 0) test-state))
  (check-false (is-move-valid? RED (make-posn 0 0) (make-posn 1 1) test-state))
  (check-false (is-move-valid? BROWN (make-posn 0 1) (make-posn 0 0) test-state))
  (check-false (is-move-valid? RED (make-posn 0 1) (make-posn 2 1) test-state))
  ;; get-player
  (check-equal? (get-player RED test-state)
                (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1))))
  (check-equal? (get-player BLACK test-state)
                (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1))))
  (check-equal? (get-player WHITE test-state)
                (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3))))
  (check-exn exn:fail? (λ () (get-player BROWN test-state)))
  ;; finalize-state
  (check-equal? (finalize-state (make-state '((4)) (list (make-player RED 0 (list (make-posn 0 0))))))
                (make-state '((0)) (list (make-player RED 4 '()))))
  (check-equal? (finalize-state test-state)
                (make-state '((1 0 0 1) (0 0 1 0) (0 0 0 0))
                            (list (make-player RED 8 '())
                                  (make-player BLACK  4 '())
                                  (make-player WHITE 12 '()))))
  ;; remove-player-penguins
  (check-equal? (remove-player-penguins test-state RED)
                (make-state '((1 2 0 1) (1 3 1 0) (5 5 0 2))
                (list (make-player RED 1 '())
                      (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                      (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3))))))
  (check-equal? (remove-player-penguins test-state BLACK)
                (make-state '((1 2 0 1) (1 3 1 0) (5 5 0 2))
                (list (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1)))
                      (make-player BLACK  0 '())
                      (make-player WHITE 5 (list (make-posn 2 0) (make-posn 2 3))))))
  (check-equal? (remove-player-penguins test-state WHITE)
                (make-state '((1 2 0 1) (1 3 1 0) (5 5 0 2))
                (list (make-player RED 1 (list (make-posn 0 1) (make-posn 2 1)))
                      (make-player BLACK  0 (list (make-posn 1 0) (make-posn 1 1)))
                      (make-player WHITE 5 '()))))
  (check-exn exn:fail? (λ () (remove-player-penguins test-state BROWN)))
  
  ;; Internal Helper Functions
  ;; penguin-color-exists?
  (check-true (penguin-color-exists? RED test-state))
  (check-false (penguin-color-exists? BROWN test-state))
  ;; penguin-at?
  (check-true (penguin-at? (make-posn 2 3) test-state))
  (check-false (penguin-at? (make-posn 1 3) test-state))
  ;; player-has-penguin-at?
  (check-true (player-has-penguin-at? WHITE (make-posn 2 3) test-state))
  (check-false (player-has-penguin-at? BLACK (make-posn 2 3) test-state))
  (check-false (player-has-penguin-at? WHITE (make-posn 1 3) test-state))
  ;; move-is-valid?
  (check-true (move-is-valid? (make-posn 0 1) (make-posn 0 0) test-state))
  (check-false (move-is-valid? (make-posn 0 1) (make-posn 2 1) test-state))
  ;; update-player-posn
  (check-equal? (update-player-posn (make-player RED 10 (list (make-posn 2 2)))
                                    (make-posn 2 2)
                                    (make-posn 1 1)
                                    5)
                (make-player RED 15 (list (make-posn 1 1))))
  (check-equal? (update-player-posn (make-player RED 10 (list (make-posn 1 1)
                                                              (make-posn 3 3)
                                                              (make-posn 2 2)))
                                    (make-posn 3 3)
                                    (make-posn 1 2)
                                    10)
                (make-player RED 20 (list (make-posn 1 1)
                                          (make-posn 1 2)
                                          (make-posn 2 2))))
  ;; add-player-posn
  (check-equal? (add-player-posn (make-player RED 10 (list (make-posn 2 2)))
                                 (make-posn 1 1))
                (make-player RED 10 (list (make-posn 1 1) (make-posn 2 2))))
  (check-equal? (add-player-posn (make-player RED 10 '())
                                 (make-posn 2 2))
                (make-player RED 10 (list (make-posn 2 2))))
  ;; penguins-to-holes
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
  ;; finalize-player
  (check-equal? (finalize-player (make-player BLACK 0 (list (make-posn 0 0))) '((4)))
                (make-player BLACK 4 '()))
  (check-equal? (finalize-player (make-player RED 0 (list (make-posn 0 0) (make-posn 0 1)
                                                          (make-posn 1 0) (make-posn  2 2)))
                                 '((1 1 1) (2 2 2) (3 3 3)))
                (make-player RED 7 '())))
