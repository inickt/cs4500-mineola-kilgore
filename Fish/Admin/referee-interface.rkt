#lang racket/base

(require racket/class
         racket/contract
         racket/math
         "../Common/board.rkt"
         "../Common/player-interface.rkt"
         "observer-interface.rkt")

(provide referee-interface)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

(define referee-interface
  (interface ()
    ;; Inputs: players, num-rows, num-columns, observers
    ;; Output: pairs of players and their respective score, kicked players
    ;; 
    ;; When called by a Tournament Manager, causes the Referee to run a game of Fish.
    ;;
    ;; The Referee determines the initial layout of the board, which will have a number of rows
    ;; specified by num-rows, and a number of columns specified by num-columns. The referee may remove
    ;; some tiles, creating holes on the initial board.
    ;;
    ;; The Referee will then determine a play order, which starts with the player who's age is lowest
    ;; and cycles through the players in a round-robin fashion.
    ;; The Referee will call `get-placement` on each player 6 - N times, where N is the number of
    ;; players.
    ;;
    ;; The Referee will then call `get-movement` on the current player of the GameTree until it
    ;; reaches an EndGame where there are no valid moves remaining.
    ;;
    ;; If, during this process, a player fails to make a move or cheats, the Referee will kick the
    ;; player from the game and then resume the game without that player or it's penguins.
    ;;
    ;; The Referee will finally return a list of the players sorted by their final score such that
    ;; the highest scores come first, and the list of players who were kicked.
    ;;
    ;; For each step of the game for which a FishGameEvent can be produced (start, placement, move,
    ;; kick, end), the Referee will call observe once on each observer of the game and pass it the
    ;; FishGameEvent.
    ;;
    ;; NOTE: The Tournament Manager must provide between 2 and 4 players, inclusive.
    ;;
    [run-game (->m (non-empty-listof (is-a?/c player-interface))
                   posint?
                   posint?
                   (listof (is-a?/c game-observer-interface))
                   (list/c (non-empty-listof (list/c (is-a?/c player-interface) natural?))
                           (listof (is-a?/c player-interface))))]))
