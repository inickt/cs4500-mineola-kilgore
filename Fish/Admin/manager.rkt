#lang racket/base

(require lang/posn
         racket/class
         racket/engine
         racket/list
         racket/match
         racket/promise
         2htdp/universe
         "referee-interface.rkt"
         "manager-interface.rkt"
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/state.rkt"
         "../Player/player.rkt")


(define manager%
  (class* object% (manager-interface)
    (super-new)
    (init-field [timeout TIMEOUT])

    (define/public (run-tournament player-age-pairs board-options observers)
      (define players (map first player-age-pairs))
      (tell-players-started players)
      (report-results (run-knock-out player-age-pairs observers)))))

;; =========== Internal =============

;; A Bracket is a (list-of (list-of (is-a?/c player-interface))))
;; INTERPRETATION: A Bracket defines one round of a knock-out elimination tournament.
;;   The inner list represents the players that will play against each other and must have 2-4 players


;; run-knock-out: (list-of (list/c (is-a?/c player-interface) posint?)) board-options? 
;; -> (list-of (is-a?/c player-interface))
;; Run the games until the tournament is over, as determined by is-tournament-over?
;;  - The number of participants has become small enough to run a single final game
(define (run-knock-out init-player-age-pairs board-options) 
  ;; run: 
  ;; (list-of (list/c (is-a?/c player-interface) posint?)) (list-of (is-a?/c player-interface))
  ;; -> (list-of (is-a?/c player-interface))
  (let run ([player-ages init-player-age-pairs]
            [last-winners '()])
    (define players (map first player-ages))
    (cond
      [(is-tournament-over? players last-winners) ]
      [(should-run-final? players) (run-game players)]
      [else (run 
             (sort (run-round player-ages observers) < #:key second) 
             players)])))

;; run-round: (list-of (is-a?/c player-interface)) -> (list-of (is-a?/c player-interface))
;; Run 1 round of knock-out and return winners
(define (run-round players board-options)
  (define bracket (create-bracket players))
  (flatten (map (λ (p) (run-game p) bracket))))


;; create-bracket: (list-of (is-a?c player-interface)) -> Bracket
;; Create a bracket for this round of the knock-out
(define (create-bracket players board-options))

;; run-game: (list-of (is-a?c player-interface)) -> (list-of (is-a?c player-interface))
;; Creates the referees and gives them players, then runs games to completions, returning the winners
(define (run-game players board-options))


;; is-tournament-over?: 
;; (list-of (is-a?c player-interface)) (list-of (is-a?c player-interface)) 
;; -> boolean?
;; Decides if the tournament is over based on:
;;  - 2 rounds produce the exact same winners
;;  - There are too few players for a single game
(define (is-tournament-over? players last-winners))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)

  (define dumb-player (new player% [depth 1]))
  (define manager (new manager%))

  (define 5by5 (make-board-options 5 5 1))

  ;; We define this constant so that we can refer to specific players by equality
  (define players (build-list 10 (λ (_) (new player% [depth 1]))))
  ;; Get the players by indices
  (define (player-n . indices) (map (λ (i) (list-ref players i)) indices))
  
  ;; Provided
  ;; run-tournament

  ;; round 1:
  ;; (0 1 2) => (0)
  (check-equal? (send manager run-tournament (take players 3) 5by5 '()) (player-n 0))

  ;; round 1:
  ;; (0 1 2 3) => (0 3)
  (check-equal? (send manager run-tournament (take players 4) 5by5 '()) (player-n 0 3))

  ;; round 1:
  ;; (0 1 2) => (0)
  ;; (3 4) => (3)
  ;; round 2:
  ;; (0 3) => (0)
  (check-equal? (send manager run-tournament (take players 5) 5by5 '()) (player-n 0))

  ;; round 1:
  ;; (0 1 2 3) => (0 3)
  ;; (4 5) => (4)
  ;; round 2:
  ;; (0 3 4) => (0)
  (check-equal? (send manager run-tournament (take players 6) 5by5 '()) (player-n 0))

  ;; round 1:
  ;; (0 1 2 3) => (0 3)
  ;; (4 5 6 7) => (4 7)
  ;; round 2:
  ;; (0 3 4 7) => (0 7)
  (check-equal? (send manager run-tournament (take players 8) 5by5 '()) (player-n 0 7)))