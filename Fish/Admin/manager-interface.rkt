#lang racket/base

(require racket/class
         racket/contract
         racket/list
         "../Common/board.rkt"
         "../Common/player-interface.rkt"
         "observer-interface.rkt"
         "referee-interface.rkt"
         "referee.rkt")

(provide manager-interface)

(define manager-interface
  (interface ()
    ;; run-tournament
    ;; Inputs: player-age-pairs, board-options, observers
    ;; Outputs: list of winners
    ;;
    ;; Runs a Fish tournament with the provided list of player/age pairs (each pair is a 2 element
    ;; list), creating game boards according to options, and reporting to Tournament Observers.
    ;;
    ;; Called by the Server Component when enough players have registered for a tournament to be run.
    ;; The Server Component may include as many house players as it chooses.
    ;; NOTE: Must be called with some number of player/age pairs >= 2.
    ;;
    ;; The age of each player is a positive number indicating the time of registration of the player.
    ;; Thus, players who register earlier will have earlier positions in the turn orderings of Fish
    ;; games.
    ;;
    ;; The tournament manager runs a round based tournament. Players are allocated into groups of 4,
    ;; unless the last group has less than 4 players in it. In the case that 2 or 3 players are left,
    ;; they will remain a group. If 1 player remains, the tournament manager it will backtrack and
    ;; the last two groups will be composed 3 and 2 players, respecively.
    ;;
    ;; The tournamant manager uses a knockout system for each round. The top finishers of each game
    ;; move on to the next round. The tournament manager runs rounds until there are too few players
    ;; for a single game, there are only enough players to run one final game, or two tournament
    ;; rounds in a row produce the same winners. Each game is run by a referee.
    ;;
    ;; Once the tournament is complete, a tournament manager will return a list of players who have
    ;; won the tournament. It is possible that if players misbehave there are no winners, and ties are
    ;; possible if the knockout system determines the tournament is over.
    ;;
    ;; The tournament manager informs all active (non-cheating) players if they have won or not. If a
    ;; winning player fails during this message, they become a loser.
    [run-tournament (->m (non-empty-listof (list/c player-interface? positive?))
                         board-options?
                         (listof tournament-observer?)
                         (listof player-interface?))]))
