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

;; A TournamentManager is an object of a class implementing the manager-interface.
(define manager-interface
  (interface ()
    ;; run-tournament
    ;; Inputs: player-age-pairs, board-options, observers
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
    ;; The tournament will be run according to the TournamentManager's specification
    ;; (see manager-protocol.md).
    ;;
    ;; Once the tournament is complete, the TournamentManager  will return a list Rankings,
    ;; sorted by player rank in ascending order such that the player(s) who won the tournament in 1st
    ;; place appear at the beginning of the list.
    [run-tournament (-> (non-empty-listof (list/c (is-a?/c player-interface) positive?))
                        board-options?
                        (listof tournament-observer?)
                        (listof (is-a?/c player-interface)))]))
