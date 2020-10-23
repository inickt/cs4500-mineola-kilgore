#lang racket/base

(require racket/contract
         racket/list
         racket/local
         "state.rkt"
         "penguin.rkt")

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct move [from to])
;; A Move is a (make-move posn? posn?)
;; and represents a penguin move on a fish board

(define-struct game [state player-turn kicked] #:transparent)
(define-struct end-game [state kicked] #:transparent)
(define game-node? (or/c game? end-game?))
;; A GameNode is one of:
;; - (make-game state? penguin? (listof? penguin?))
;; - (make-end-game state? (listof? penguin?)])
;; INVARIANT: All GameNodes that are make-games have at least one valid move for the current player

;; TODO Interpretation

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : state? -> game-node?
;; Creates a game with the provided state, where the current player is the first player in the state
;; and there are no kicked players
(define (create-game state)
  (if (can-any-move? state)
      ;; Sets current to the first player in the list who has a valid move
      (make-game state (next-turn state (last (state-players state))) '())
      (make-end-game state '())))

;; is-valid-move? : game? move? -> boolean?
;; Is the given move (by the current player in the provided game) valid?
(define (is-valid-move? game move)
  (is-move-valid? (game-player-turn game) (move-from move) (move-to move) (game-state game)))

;; apply-move : game? move? -> game-node?
;; Creates the next game state for a given valid move by the current player in the provided game
;; NOTES:
;; - Constructs an end-game if the resultant Game has no valid moves
;; - Skips the turns of players who cannot move
(define (apply-move game move)
  (when (not (is-valid-move? game move))
    (raise-arguments-error 'apply-move
                           "The move is not valid in the given game"
                           "move" move))
  
  (define current-player (game-player-turn game))
  (define kicked-players (game-kicked game))
  (define new-state (move-penguin current-player
                                  (move-from move)
                                  (move-to move)
                                  (game-state game)))
  (if (can-any-move? new-state)
      (make-game new-state (next-turn new-state current-player) kicked-players)
      (make-end-game (finalize-state new-state) kicked-players)))

;; all-possible-moves : game? -> (hash/c move? game-node?)
;; Builds a mapping of valid moves to their resulting game when applied to the given game
(define (all-possible-moves game)
  (define current-state (game-state game))
  (define current-player (get-player (game-player-turn game) current-state))

  (for*/hash (;; Iterate over all posns the current player has penguins at
              [from-posn (player-places current-player)]
              ;; Iterate over all locations to which the current player can make a valid move
              [to-posn (valid-moves from-posn current-state)]
              ;; Bind the move and skip it if invalid
              [potential-move (in-value (make-move from-posn to-posn))]
              #:when (is-valid-move? potential-move))
    (values potential-move (apply-move game potential-move))))

;; next turn : state? penguin? -> penguin?
;; Determines the color of the next player in the game, skipping players who cannot move
(define (next-turn state current)
  (local [;; next-turn-h : state? penguin? penguin? -> penguin?
          ;; Recursively query until player with color current has valid moves in state
          (define (next-turn-h state current original)
            (when (penguin=? current original)
              (raise-arguments-error 'next-turn "State has no valid moves" "state" state))
            (define next-color (get-next-color (state-players state) current))
            (if (can-color-move? next-color state)
                next-color
                (next-turn state next-color)))]
    ;; Get the next color in the list, then recurively query until a color with valid moves is found
    (define next-color (get-next-color (state-players state) current))
    (next-turn-h state next-color current)))

;; get-next-color : (list-of player?) penguin? -> penguin?
;; Get the color of the player in the list after the player with the current color
(define (get-next-color order current)
  (define current-index (index-of (map player-color order) current penguin=?))
  (player-color (list-ref order (modulo (add1 current-index) (length order)))))

;; TODO kick player fn

;; TODO test create-game with blocked-in penguin at first of player list