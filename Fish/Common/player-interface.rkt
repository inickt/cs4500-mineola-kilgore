#lang racket/base

(require lang/posn
         racket/class
         racket/math
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/penguin.rkt"
         "../Common/state.rkt")

(provide player-interface)

;; +-------------------------------------------------------------------------------------------------+
;; INTERFACE

;; The PlayerInterface is the API for a player in a Fish game.
;; Software components that implement this interface may be entered into Fish games and tournaments.
;; The goal of the player is to only perform legal actions to win a game of Fish by moving penguins
;; around the board and collecting fish to score points.
(define player-interface
  (interface ()
    ;; Initializes a player with the initial board, number of players, and the color of this player's
    ;; penguins. Returns this players age (in years).
    [initialize (->m board? natural? penguin? natural?)]

    ;; Determines where to place this players next penguin given the current state
    [get-placement (->m state? posn?)]

    ;; Determines where to move a player's penguin given the current state of the Game
    [get-move (->m game? move?)]

    ;; Informs the player about updates to the GameTree
    ;; NOTE: This can be safely ignored if the player does care about updates to the GameTree
    ;;       occuring on other players' turns
    [listen (->m game-tree? void?)]

    ;; Informs the player that they were kicked from a Game, with a given reason why
    [terminate (->m string? void?)]

    ;; Receives the final EndGame state, where no more moves are possible
    [finalize (->m end-game? void?)]))
