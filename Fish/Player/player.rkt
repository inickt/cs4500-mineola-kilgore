#lang racket/base

(require racket/class
         "../Common/player-interface.rkt"
         (prefix-in strategy: "strategy.rkt"))

(provide player%)

(define DEFAULT-SEARCH-DEPTH 2)

(define player%
  (class* object% (player-interface)
    (init [depth DEFAULT-SEARCH-DEPTH])
    (define search-depth depth)
    (super-new)
    (define/public (initialize board num-players color)
      (void))

    (define/public (get-placement state)
      (strategy:get-placement state))
    
    (define/public (get-move game)
      (strategy:get-move game search-depth))

    (define/public (listen game-tree)
      (void))

    (define/public (terminate message)
      (void))

    (define/public (finalize end-game)
      (void))))

  #|
    [initialize (->m board? natural? penguin-color? natural?)]

    ;; Determines where to place this players next penguin given the current state.
    ;; The Referee will call this up to 6 - N times, where N is the number of players in the game.
    [get-placement (->m state? posn?)]

    ;; Determines where to move a player's penguin given the current state of the Game.
    ;; The Referee will call this once on each of this player's turns until the Game reaches an
    ;; EndGame state in which no more moves are possible. This function will not be called on this
    ;; player's turns if this player has no remaining moves (the player will be skipped).
    [get-move (->m game? move?)]

    ;; Informs the player about updates to the GameTree.
    ;; The Referee will call this once per action that occurs on the GameTree, changing it's state.
    ;; NOTE: This can be safely ignored if the player does care about updates to the GameTree
    ;;       occuring on other players' turns
    [listen (->m game-tree? void?)]

    ;; Informs the player that they were kicked from a Game, with a given reason why.
    ;; The Referee will call this exactly once if/when a player attempts to cheat or fails to play.
    [terminate (->m string? void?)]

    ;; Receives the final EndGame state, where no more moves are possible.
    ;; The Referee will call this exactly once with the final state of the Game when it ends.
    [finalize (->m end-game? void?)])
|#
  