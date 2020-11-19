#lang racket/base

(require lang/posn
         racket/bool
         racket/class
         racket/contract
         racket/engine
         racket/list
         racket/match
         racket/promise
         racket/set
         2htdp/universe
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/player-interface.rkt"
         "../Common/state.rkt"
         "../Player/player.rkt"
         "bad-players.rkt"
         "referee-interface.rkt"
         "referee.rkt"
         "manager-interface.rkt"
         "util.rkt")

(provide manager%
         (contract-out [get-winners (-> (listof player-result?) (listof player-interface?))]))

;; +-------------------------------------------------------------------------------------------------+
;; CONSTANTS

(define TIMEOUT 30)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

(define manager%
  (class* object% (manager-interface)
    (super-new)
    (init-field [timeout TIMEOUT])

    (define/public (run-tournament player-age-pairs board-options observers)
      ;; TODO is this sorted? make sure documented in interface
      (define players (map first player-age-pairs))
      (define bad-players (tell-players-starting players timeout))
      ;; TODO handle bad players

      (define winning-players (run-knock-out player-age-pairs observers))
      ;; TODO do we tell all players or only winners? will change signature/implementation
      (define winning-players-to-kick (tell-players-ending winning-players))
      ;; TODO get rid of winning players that didn't respond from final answer
      '())))

;; get-winners : (listof player-result?) -> (listof player-interface?)
;; Return the winning players based on their score, removing any kicked players
(define (get-winners player-results)
  (if (empty? player-results)
      empty
      (let ([max-score (apply max (map player-result-score player-results))])
        (filter-map (λ (player-result) (and (= (player-result-score player-result) max-score)
                                            (player-result-player player-result)))
                    player-results))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

(define-struct result [winners kicked] #:transparent)
;; A Result is a (make-result (listof player-interface?) (set/c player-interface?)
;; and represents the results from a tournament round/game with the winners and players kicekd

;; tell-players-starting : (non-empty-listof player-interface?) number? -> (listof player-interface?)
;; Informs players the tournament is starting (with the initial number of players) and returns players
;; that should be kicked, caused by them timing or erroring out.
(define (tell-players-starting players timeout)
  (filter (λ (player)
            (false? (run-with-timeout 
                     (λ () (send player tournament-started (length players))) 
                     (λ (_) (void)) 
                     timeout)))
          players))

;; tell-players-ending : (listof player-interface?) number? -> (listof player-interface?)
;; Informs players the tournament is ending and whether they have won or not. Returns players
;; that should be kicked, caused by them timing or erroring out.
(define (tell-players-ending players)
  (void))

;; run-knock-out : (non-empty-listof (list/c player-interface? positive?)) board-options? number?
;;                 -> (listof player-interface?)
;; Run the games until the tournament is over, as determined by is-tournament-over?
;;  - The number of participants has become small enough to run a single final game
(define (run-knock-out init-player-age-pairs board-options timeout) 
  ;; run : (non-empty-listof (list/c player-interface? positive?)) (listof player-interface?)
  ;;        -> (listof player-interface?)
  (let run ([player-ages init-player-age-pairs]
            [last-winners '()])
    (define players (map first player-ages))
    (cond
      [(is-tournament-over? players last-winners) ]
      [(should-run-final? players) (run-game players)]
      [else (run 
             (sort (run-round player-ages) < #:key second) 
             players)])))

;; run-round : (non-empty-listof player-interface?) board-options? number? -> result?
;; Run 1 round of knock-out and return winners (unsorted)
(define (run-round players board-options timeout)
  (define player-groupings (allocate-items players))
  (apply append-results
         (map (λ (players) (run-game players board-options timeout)) player-groupings)))

;; allocate-items : (non-empty-listof any/c) -> (non-empty-listof (non-empty-listof any/c))
;; Create groups (size 2-4) of items. Items will attempted to be put into groups of 4, unless the last
;; group has less than 4 items in it. In the case that 2 or 3 items are left, that will remain the
;; last grouping. If 1 item remains, then it will backtrack and the last two groups will be composed
;; of 3 and 2 items, respecively. The items remain in the same order as the initial list.
;; INVARIANT: There must be at least 2 elements in the given list
(define (allocate-items initial-items)
  (let allocate ([items initial-items]
                 [groups-so-far '()])
    (define remaining (length items))
    (define next-remaining (- remaining 4))
    (cond [(<= remaining 4) (append groups-so-far (list items))]
          [(= next-remaining 1) (append groups-so-far (list (take items 3) (drop items 3)))]
          [else (allocate (drop items 4) (append groups-so-far (list (take items 4))))])))

;; run-game : (non-empty-listof player-interface?) board-options? number? -> result?
;; Creates the referees and gives them players, then runs games to completions, returning the winners
(define (run-game players board-options timeout)
  (define ref (new referee% [timeout timeout]))
  (define game-result (send ref run-game players board-options '()))
  (make-result (get-winners (game-result-players game-result)) (game-result-kicked game-result)))

;; is-tournament-over? : (listof player-interface?) (listof player-interface?) -> boolean?
;; Decides if the tournament is over based on:
;;  - 2 rounds produce the exact same winners
;;  - There are too few players for a single game
(define (is-tournament-over? players last-winners)
  (void))

(define (should-run-final? players)
  (void))

;; append-results : result? ...  -> result?
;; Combines any number of results into a singular result
(define (append-results . results)
  (foldr (λ (r1 r2)
           (make-result (append (result-winners r1) (result-winners r2))
                        (set-union (result-kicked r1) (result-kicked r2))))
         (make-result '() (set))
         results))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit
           "./bad-players.rkt")

  (define dumb-player (new player% [depth 1]))
  (define bad-player1 (new bad-player-error%))
  (define bad-player2 (new bad-player-error%))
  (define manager (new manager%))

  (define 5by5 (make-board-options 5 5 1))

  ;; We define this constant so that we can refer to specific players by equality
  (define players (build-list 10 (λ (_) (new player% [depth 1]))))
  ;; Get the players by indices
  (define (player-n . indices) (map (λ (i) (list-ref players i)) indices))
  
  ;; Provided
  ;; +--- run-tournament ---+

  #|
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
  (check-equal? (send manager run-tournament (take players 8) 5by5 '()) (player-n 0 7))
  |#

  ;; +--- get-winners ---+
  (define p1 (new player% [depth 1]))
  (define p2 (new player% [depth 1]))
  (define p3 (new player% [depth 1]))
  
  (check-equal? (get-winners (list (make-player-result p1 2)
                                   (make-player-result p2 2)
                                   (make-player-result p3 2)))
                (list p1 p2 p3))
  (check-equal? (get-winners (list (make-player-result p1 5)
                                   (make-player-result p2 2)
                                   (make-player-result p3 2)))
                (list p1))
  (check-equal? (get-winners (list (make-player-result p1 1)
                                   (make-player-result p2 2)
                                   (make-player-result p3 2)))
                (list p2 p3))
                             

  ;; Internal Helper Functions
  ;; +--- tell-players-starting ---+
  (check-equal? (tell-players-starting (list dumb-player dumb-player) 1) '())
  (check-equal? (tell-players-starting (list bad-player1 dumb-player) 1) (list bad-player1))

  ;; +--- tell-players-ending ---+
  #|
  (check-equal? (tell-players-ending (list dumb-player dumb-player) 1) '())
  (check-equal? (tell-players-ending (list bad-player-error dumb-player) 1) (list bad-player-error))
  |#

  ;; +--- run-round ---+
  (check-equal? (run-round (take players 2) 5by5 1)
                (make-result (player-n 0) (set)))
  (check-equal? (run-round (take players 3) 5by5 1)
                (make-result (player-n 0) (set)))
  (check-equal? (run-round (take players 4) 5by5 1)
                (make-result (player-n 0 3) (set)))
  (check-equal? (run-round (take players 5) 5by5 1)
                (make-result (player-n 0 3) (set)))
  (check-equal? (run-round (take players 9) 5by5 1)
                (make-result (player-n 0 3 4 7) (set)))

  ;; +--- allocate-items ---+
  (check-equal? (allocate-items (build-list 2 add1)) '((1 2)))
  (check-equal? (allocate-items (build-list 3 add1)) '((1 2 3)))
  (check-equal? (allocate-items (build-list 4 add1)) '((1 2 3 4)))
  (check-equal? (allocate-items (build-list 5 add1)) '((1 2 3) (4 5)))
  (check-equal? (allocate-items (build-list 6 add1)) '((1 2 3 4) (5 6)))
  (check-equal? (allocate-items (build-list 7 add1)) '((1 2 3 4) (5 6 7)))
  (check-equal? (allocate-items (build-list 8 add1)) '((1 2 3 4) (5 6 7 8)))
  (check-equal? (allocate-items (build-list 9 add1)) '((1 2 3 4) (5 6 7) (8 9)))
  (check-equal? (allocate-items (build-list 10 add1)) '((1 2 3 4) (5 6 7 8) (9 10)))

  ;; +--- run-game ---+
  ;; no kicked, one winner
  (check-equal? (run-game (list p1 p2 p3) 5by5 2) (make-result (list p1) (set)))
  ;; no kicked, two winners
  (check-equal? (run-game (take players 4) 5by5 2) (make-result (player-n 0 3) (set)))
  ;; two kicked, one winner
  (check-equal? (run-game (list bad-player1 p1 bad-player2 p2) 5by5 2)
                (make-result (list p1) (set bad-player1 bad-player2)))
  ;; all kicked, no winners
  (check-equal? (run-game (list bad-player1 bad-player2) 5by5 1)
                (make-result '() (set bad-player1 bad-player2)))

  ;; +--- append-results ---+
  (check-equal? (append-results) (make-result '() (set)))
  (check-equal? (append-results (make-result '() (set))) (make-result '() (set)))
  (check-equal? (append-results (make-result (list p1 p2) (set p3))
                                (make-result (list bad-player1) (set bad-player2)))
                (make-result (list p1 p2 bad-player1) (set p3 bad-player2)))
  
  )