#lang racket/base

(require lang/posn
         racket/class
         racket/engine
         racket/list
         racket/match
         racket/promise
         2htdp/universe
         "referee-interface.rkt"
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/manager-interface.rkt"
         "../Common/state.rkt"
         "../Player/player.rkt")


(define manager%
  (class* object% (manager-interface)
    (super-new)
    (init-field [timeout TIMEOUT])

    (define/public (run-tournament player-age-pairs observers)
      (define players (map first player-age-pairs))
      (tell-players-started players)
      (report-results (run-knock-out player-age-pairs observers)))))


;; Run the games until the tournament is over, as determined by is-tournament-over?
;;  - The number of participants has become small enough to run a single final game
(define (run-knock-out player-age-pairs observers last-winners) 
  (define players (map first player-age-pairs))
  (cond
    [(is-tournament-over? players last-winners) ]
    [(should-run-final? players) (run-game players)]
    [else (run-knock-out (sort (run-round player-age-pairs observers) TODO) observers player-age-pairs)])
  )


;; A Bracket is a (list-of (list-of (is-a?/c player-interface))))
;; INTERPRETATION: A Bracket defines one round of a knock-out elimination tournament.
;;   The inner list represents the players that will play against each other and must have 2-4 players

;; run-round: (list-of (is-a?/c player-interface)) -> (list-of (is-a?/c player-interface))
;; Run 1 round of knock-out and return winners
(define (run-round players)
  (define bracket (create-bracket players))
  (flatten (map (λ (p) (run-game p) bracket))))


;; create-bracket: (list-of (is-a?c player-interface)) -> Bracket
;; Create a bracket for this round of the knock-out
(define (create-bracket players))

;; run-game: (list-of (is-a?c player-interface)) -> (list-of (is-a?c player-interface))
;; Creates the referees and gives them players, then runs games to completions, returning the winners
(define (run-game players))


;; is-tournament-over?: 
;; (list-of (is-a?c player-interface)) (list-of (is-a?c player-interface)) 
;; -> boolean?
;; Decides if the tournament is over based on:
;;  - 2 rounds produce the exact same winners
;;  - There are too few players for a single game
(define (is-tournament-over? players last-winners))