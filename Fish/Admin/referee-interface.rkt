#lang racket/base

(require racket/bool
         racket/class
         racket/contract
         racket/math
         "../Common/board.rkt"
         "../Common/player-interface.rkt"
         "observer-interface.rkt")

(provide board-options
         (contract-out [make-board-options
                        (-> posint? posint? (or/c (integer-in 1 5) false?) board-options?)])
         (contract-out [board-options-rows (-> board-options? posint?)])
         (contract-out [board-options-columns (-> board-options? posint?)])
         (contract-out [board-options-fish (-> board-options? (or/c (integer-in 1 5) false?))])
         (contract-out [board-options? (-> any/c boolean?)])
         player-result
         (contract-out [make-player-result (-> player-interface? natural? player-result?)])
         (contract-out [player-result-player (-> player-result? player-interface?)])
         (contract-out [player-result-score (-> player-result? natural?)])
         (contract-out [player-result? (-> any/c boolean?)])
         game-result
         (contract-out [make-game-result
                        (-> (listof player-result?) (listof player-interface?) game-result?)])
         (contract-out [game-result-players (-> game-result? (listof player-result?))])
         (contract-out [game-result-kicked (-> game-result? (listof player-interface?))])
         (contract-out [game-result? (-> any/c boolean?)])
         referee-interface)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

(define-struct board-options [rows columns fish] #:transparent)
;; A BoardOptions is a (make-board posint? posint? (or/c (integer-in 1 5) false?))
;; and represents options available for configuring a board in a Fish game where
;; rows and columns are the number of rows and columns in the board and
;; fish is the number of fish on every tile or #f for a randomized board with holes

(define-struct player-result [player score] #:transparent)
;; A PlayerResult is a (make-player-result player-interface? natural?)
;; and represents a player and their score at the end of a Fish game

(define-struct game-result [players kicked] #:transparent)
;; A GameResult is a (make-game-result (listof player-result?) (listof player-interface?))
;; and represents the players/their scores that completed the game and players that were kicked.

(define referee-interface
  (interface ()
    ;; Inputs: players, board options, observers
    ;; Output: a pair of players and their respective score and kicked players
    ;; 
    ;; When called by a Tournament Manager, causes the Referee to run a game of Fish.
    ;;
    ;; The Referee determines the initial layout of the board, which will have a number of rows
    ;; a number of columns, and number of fish on every tile (or a random board with holes) based on
    ;; the provided board options.
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
    ;; A player is considered cheating when:
    ;; - they try to take an action not considered valid by the rules of the game
    ;; A player fails to take an action when:
    ;; - they timeout
    ;; - they throw an error
    ;;
    ;; The Referee will finally return a list of the players sorted by their final score such that
    ;; the highest scores come first (remiving kicked players), and the list of players who were
    ;; kicked from the game.
    ;;
    ;; For each step of the game for which a FishGameEvent can be produced (start, placement, move,
    ;; kick, end), the Referee will call observe once on each observer of the game and pass it the
    ;; FishGameEvent.
    ;;
    ;; NOTE: The Tournament Manager must provide between 2 and 4 players, inclusive.
    ;;
    [run-game (->m (non-empty-listof player-interface?)
                   board-options?
                   (listof (is-a?/c game-observer-interface))
                   game-result?)]))
