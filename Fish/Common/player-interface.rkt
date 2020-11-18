#lang racket/base

(require lang/posn
         racket/class
         racket/math
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/penguin-color.rkt"
         "../Common/state.rkt")

(provide player-interface player-interface?)

;; +-------------------------------------------------------------------------------------------------+
;; INTERFACE

;; The PlayerInterface is the API for a player in a Fish game.
;; Software components that implement this interface may be entered into Fish games and tournaments.
;; The goal of the player is to only perform legal actions to win a game of Fish by moving penguins
;; around the board and collecting fish to score points.
(define player-interface
  (interface ()
    ;; Informs a player that the tournament is about to begin.
    ;; The Tournament Manager calls this when the tournament this player is entered into is starting.
    [tournament-started (->m natural? void?)]

    ;; Informs a player that the tournament has ended and whether they have won or not.
    ;; The Tournament Manager calls this when the tournament this player is entered into is ending.
    [tournament-ended (->m boolean? void?)]

    ;; Initializes a player with the initial board, number of players, and the color of this player's
    ;; penguins.
    ;; The Referee will call this once when the game is initialized, to provide the player with the
    ;; initial board, a color, and the number of opponents.
    [initialize (->m board? natural? penguin-color? void?)]

    ;; Determines where to place this players next penguin given the current state.
    ;; The Referee will call this up to 6 - N times, where N is the number of players in the game.
    [get-placement (->m state? posn?)]

    ;; Determines where to move a player's penguin given the current game state.
    ;; The Referee will call this once on each of this player's turns until the Game reaches an
    ;; EndGame state in which no more moves are possible. This function will not be called on this
    ;; player's turns if this player has no remaining moves (the player will be skipped).
    [get-move (->m state? move?)]

    ;; Informs the player that they were kicked from a game.
    ;; The Referee will call this exactly once if/when a player attempts to cheat or fails to play.
    [terminate (->m void?)]

    ;; Receives the final game state, where no more moves are possible.
    ;; The Referee will call this exactly once with the final state of the game when it ends.
    [finalize (->m state? void?)]))

;; Shorthand for something that implements a player interface, used for signatures
(define player-interface? (is-a?/c player-interface))
