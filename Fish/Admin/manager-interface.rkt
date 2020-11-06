#lang racket/base

(require racket/class
         racket/contract
         "../Common/board.rkt"
         "../Common/player-interface.rkt"
         "observer-interface.rkt"
         "referee.rkt")

(provide ranking?
         manager-interface)

;; A Ranking is a (list (is-a?/c player-interface) posint?)
(define ranking? (list/c (is-a?/c player-interface) posint?))
;; representing a player-interface implementing object and that player's rank within a Fish
;; tournament.
;;
;; Ranks are not necessarily unique within a Fish tournament.
;; If players in a tournament tie, they share the highest rank achieved, and the following ranks
;; skip the number of tying players minus 1.
;; For example:
;; (list (list P1 1) (list P2 2) (list P3 2) (list P4 2) (list P5 5))
;; Represents a list of Rankings in a tournament with 5 players where P1 is 1st, P2-P4 tie for 2nd,
;; and P5 comes in 5th.

;; A TournamentManager is an object of a class implementing the manager-interface.
(define manager-interface
  (interface ()
    ;; run-tournament
    ;; Inputs: player-age-pairs, observers
    ;;
    ;; Runs a Fish tournament with the provided list of player/age pairs (each pair is a 2 element
    ;; list), and the provided list of Tournament Observers.
    ;;
    ;; Called by the Server Component when enough players have registered for a tournament to be run.
    ;; The Server Component may include as many house players as it chooses.
    ;; NOTE: Must be called with some number of player/age pairs >= 2.
    ;;
    ;; The age of each player is a positive number indicating the time of registration of the player.
    ;; Thus, players who register earlier will have earlier positions in the turn orderings of Fish
    ;; games.
    ;;
    ;; The tournament will be run according to the Tournament Manager's specification
    ;; (see manager-protocol.md).
    ;;
    ;; Once the tournament is complete, the Tournament Manager  will return a list Rankings,
    ;; sorted by player rank in ascending order such that the player(s) who won the tournament in 1st
    ;; place appear at the beginning of the list.
    [run-tournament (-> (non-empty-listof (list/c (is-a?/c player-interface) positive?))
                        (listof tournament-observer?)
                        (listof ranking?))]))
