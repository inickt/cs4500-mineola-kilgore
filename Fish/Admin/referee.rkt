#lang racket/base

(require lang/posn
         racket/class
         racket/contract
         racket/engine
         racket/list
         racket/math
         racket/promise
         "referee-interface.rkt"
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/player-interface.rkt"
         "../Common/state.rkt"
         "../Player/player.rkt")

(provide referee%)

;; +-------------------------------------------------------------------------------------------------+
;; CONSTANTS

(define INIT-MAX-HOLE-RATIO 1/5)
(define TIMEOUT 30)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

(define referee%
  (class* object% (referee-interface)
    (super-new)
    (init-field [timeout TIMEOUT])
    
    (define/public (subscribe-as-game-observer game-observer)
      (void))
    ;; NOTE: Not implemented as of Milestone 6
    ;; The spec for this may vary drastically pending the method in which the game is networked,
    ;; so we have chosen to hold off on implementing this for now.
    
    (define/public (remove-game-observer game-observer)
      (void))
    ;; NOTE: Not implemented as of Milestone 6
    ;; The spec for this may vary drastically pending the method in which the game is networked,
    ;; so we have chosen to hold off on implementing this for now.

    (define/public (run-game players num-cols num-rows)
      (define init-board (create-initial-board num-cols num-rows (length players)))
      (define init-state (create-state (length players) init-board))
      (define player-color-map (create-player-color-map players init-state))

      (for ([(color player) (in-hash player-color-map)])
        (send player initialize init-board (length players) color))
      
      (define-values (state-with-placements kicked)
        (get-all-placements init-state player-color-map timeout))
      
      (define-values (final-game final-kicked)
        (play-game (create-game state-with-placements) player-color-map kicked timeout))
      (define results (state-players (end-game-state final-game)))

      (for ([(color player) (in-hash player-color-map)])
        (send player finalize final-game))
      
      (list (map (λ (player) (list (hash-ref player-color-map (player-color player))
                                   (player-score player)))
                 (get-rankings results final-kicked))
            (map (λ (player) (hash-ref player-color-map player)) final-kicked)))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; create-player-color-map : (non-empty-listof (is-a?/c player-interface)) state?
;;                           -> (hash/c penguin-color? (is-a?/c player-interface))
;; Creates a mapping of player penguin-color to player-interface implementing object
;; NOTES:
;; - Players and state players must be the same length
(define (create-player-color-map players state)
  (for/hash ([color (map player-color (state-players state))]
             [player players])
    (values color player)))

;; create-initial-board : posint? posint? posint? -> board?
;; Builds an initial board with the given number of rows, columns, and players
;; NOTE:
;; - num-rows * num-cols >= num-players
;; - Uses INIT-MAX-HOLE-RATIO to determine the number of board tiles that can be initialized as holes
(define (create-initial-board num-rows num-cols num-players)
  (make-board-with-holes
   num-rows
   num-cols
   (build-random-holes
    (floor (* (- (* num-rows num-cols)
                 (* num-players (penguins-per-player num-players)))
              INIT-MAX-HOLE-RATIO))
    num-rows
    num-cols)
   num-players))

;; build-random-holes : posint? posint? natural? -> (list-of posn?)
;; Builds a list of up to n random holes on a board with given width and height
(define (build-random-holes n num-rows num-cols)
  (remove-duplicates (build-list n (λ (_) (make-posn (random num-cols) (random num-rows))))))

;; get-all-placements : state? (hash-of penguin-color? (is-a?/c player-interface?)) positive?
;;                      -> state? (listof penguin-color?)
;; Recursively gets placements for the current player until each player has 
(define (get-all-placements initial-state player-color-map timeout)
  (let place ([state initial-state]
              [kicked '()])
    (if (all-penguins-placed? state kicked)
        (values state kicked)
        (let ([color (state-current-player state)])
          (if (member color kicked)
              (place (skip-player state) kicked)
              (let ([maybe-state
                     (get-single-placement state (get-player player-color-map state) timeout)])
                (if (not maybe-state)
                    (place (skip-player (remove-penguins state color)) (cons color kicked))
                    (place maybe-state kicked))))))))

;; get-single-placement : state? (is-a?/c player-interface?) positive? -> (or/c state? false?)
;; Gets a single placement from the current player. Returns false if the placement is invalid or
;; if timer expires before the placement has been chosen.
(define (get-single-placement state player timeout)
  (run-with-timeout
   (λ () (send player get-placement state))
   (λ (result-posn) (place-penguin state result-posn))
   timeout))

;; get-player :
;; (hash-of penguin-color? (is-a?/c player-interface?)) state? -> (is-a?/c player-interface?))
;; Gets the player object assigned the given color
;; NOTE: The player color has an assigned player
(define (get-player player-color-map state)
  (hash-ref player-color-map (player-color (state-current-player state))))

;; all-penguins-placed? : state? (listof penguin-color?) -> boolean?
;; Are all of the players penguins placed on the board?
(define (all-penguins-placed? state kicked)
  (define num-penguins (penguins-per-player (length (state-players state))))
  (andmap (λ (player) (= (length (player-places player)) num-penguins))
          (filter (λ (player) (not (member (player-color player) kicked)))
                  (state-players state))))

;; penguins-per-player : posint? -> posint?
;; Determines the number of penguins per player
(define (penguins-per-player n) (- 6 n))

;; play-game :
;; game-tree? (hash-of penguin-color? (is-a?/c player-interface?)) (list-of penguin-color?) positive?
;; -> end-game? (listof penguin-color?)
;; Plays a complete game of Fish by querying each player for its desired move.
;; NOTE: If a player cheats, or exceeds the timeout threshold for choosing a move, it is kicked from
;; the game, and the game continues with that player's penguins removed from the board.
(define (play-game initial-game player-color-map initial-kicked timeout)
  (let play ([game initial-game]
             [kicked '()])
    (if (end-game? game)
        (values game kicked)
        (let* ([player-color (player-color (state-current-player (game-state game)))]
               [player (get-player player-color-map (game-state game))]
               [maybe-game-tree (play-one-move game player timeout)])
          (if (not maybe-game-tree)
              (begin (send player terminate)
                     (play (kick-player game player-color) (cons player-color kicked)))
              (play maybe-game-tree kicked))))))

;; play-one-move : game? (is-a?/c player-interface?) positive? -> (or/c false? game-tree?)
;; Gets a player's move and applies it to the given game tree
;; NOTES:
;; - It must be the given player's turn in the provided game
;; - If a player cheats or exceeds the timeout threshold returns false, else returns the new GameTree
(define (play-one-move game player timeout)
  (define children (force (game-children game)))
  (run-with-timeout
   (λ () (send player get-move game))
   (λ (result-move) (hash-ref children result-move))
   timeout))

;; kick-player : game? penguin-color -> game-tree?
;; Removes the player with the given color from the GameTree by removing their penguins
(define (kick-player game penguin-color)
  (create-game (remove-penguins (game-state game) penguin-color)))

;; run-with-timeout : (X Y) (-> X) (X -> Y) positive? -> (or/c Y false?)
;; Runs run-proc for up to TIMEOUT seconds, then calls result-proc on the result value
;; Returns false if run-proc times out, or if either run-proc or result-proc error
(define (run-with-timeout run-proc result-proc timer)
  (define run-engine (engine (λ (_) (run-proc))))
  (with-handlers ([exn:fail? (λ (exn) #f)])
    (engine-run (* timer 1000) run-engine)
    (if (engine-result run-engine)
        (result-proc (engine-result run-engine))
        (engine-result run-engine))))
  
;; get-rankings : (listof player?) (listof penguin-color?) -> (listof player?)
;; Filters out kicked players and returns the list of players sorted in descending order by score
(define (get-rankings players kicked)
  (sort (filter (λ (player) (not (member (player-color player) kicked))) players)
        >
        #:key player-score))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit
           "../Common/penguin-color.rkt")

  (define test-state (make-state '((1 0 5 3) (3 3 3 5) (1 1 2 2))
                                 (list (make-player RED 0 (list (make-posn 0 0)
                                                                (make-posn 1 1)))
                                       (make-player BLACK 1 (list (make-posn 1 0)
                                                                  (make-posn 2 1)))
                                       (make-player WHITE 2 (list (make-posn 2 0)
                                                                  (make-posn 0 2))))))
  (define children (force (game-children (create-game test-state))))
  (define dumb-player (new player% [depth 1]))
  (define smart-player (new player% [depth 2]))
  (define test-timeout 0.1)
  (define strict-referee (new referee% [timeout test-timeout]))
  (define lenient-referee (new referee% [timeout 5]))
  ;; Provided
  ;; Internal Helper Functions
  ;; +--- create-player-color-map ---+
  (check-equal? (create-player-color-map (list dumb-player smart-player)
                                         (make-state '((1)) (list (make-player RED 0 '())
                                                                  (make-player BLACK 0 '()))))
                (hash RED dumb-player BLACK smart-player))
  ;; +--- create-initial-board ---+
  (check-equal? (length (create-initial-board 4 3 2)) 4)
  (check-equal? (length (first (create-initial-board 4 3 2))) 3)
  (check-true (<= (foldr (λ (tile count) (if (zero? tile) (add1 count) count))
                         0
                         (foldr append '() (create-initial-board 4 4 2)))
                  (floor (* INIT-MAX-HOLE-RATIO 8))))
  ;; +--- build-random-holes ---+
  (check-equal? (length (build-random-holes 0 4 4)) 0)
  (check-true (<= (length (build-random-holes 4 4 4)) 4))
  (check-false (check-duplicates (build-random-holes 25 10 10)))
  ;; +--- get-all-placements ---+
  ;; +--- get-single-placement ---+
  ;; +--- get-player ---+
  (check-equal? (get-player (hash RED dumb-player BLACK smart-player) test-state) dumb-player)
  (check-equal? (get-player (hash RED dumb-player BLACK smart-player)
                            (make-state '((1)) (list (make-player BLACK 0 '())
                                                     (make-player RED 0 '()))))
                smart-player)
  ;; +--- all-penguins-placed? ---+
  (check-false (all-penguins-placed? test-state '()))
  (check-true (all-penguins-placed?
               (make-state '((1 0 5 3) (3 3 3 5) (1 1 2 2))
                           (list (make-player RED 0 (list (make-posn 0 0)
                                                          (make-posn 1 1)))
                                 (make-player BLACK 1 (list (make-posn 1 0)
                                                            (make-posn 2 1)))
                                 (make-player WHITE 2 (list (make-posn 2 0)
                                                            (make-posn 0 2)))
                                 (make-player BROWN 3 '())))
               (list BROWN)))
  ;; +--- penguins-per-player ---+
  (check-equal? (penguins-per-player 2) 4)
  (check-equal? (penguins-per-player 3) 3)
  (check-equal? (penguins-per-player 4) 2)
  ;; +--- play-game ---+
  ;; +--- play-one-move ---+
  (check-equal? (game-state (play-one-move (create-game test-state) dumb-player 1))
                (game-state (hash-ref children (make-move (make-posn 1 1) (make-posn 1 2)))))
  (check-false (play-one-move (create-game test-state) smart-player 0.0001))
  (check-equal? (game-state (play-one-move (create-game test-state) smart-player 30))
                (game-state (hash-ref children (make-move (make-posn 1 1) (make-posn 2 2)))))
  ;; +--- kick-player ---+
  (check-equal? (game-state (kick-player (create-game test-state) RED))
                (make-state '((1 0 5 3) (3 3 3 5) (1 1 2 2))
                            (list (make-player BLACK 1 (list (make-posn 1 0)
                                                             (make-posn 2 1)))
                                  (make-player WHITE 2 (list (make-posn 2 0)
                                                             (make-posn 0 2)))
                                  (make-player RED 0 '()))))
  (check-equal? (kick-player
                 (create-game (make-state '((1 0 0 1 1))
                                          (list (make-player RED 0 (list (make-posn 0 3)))
                                                (make-player WHITE 0 (list (make-posn 0 0))))))
                 RED)
                (create-game (make-state '((1 0 0 1 1))
                                         (list (make-player RED 0 '())
                                               (make-player WHITE 0 '())))))
  ;; +--- run-with-timeout ---+
  (check-false (run-with-timeout (λ () (sleep 10)) (λ (result) result) 0.01))
  (check-false (run-with-timeout (λ () (error "Error")) (λ (result) result) 10))
  (check-equal? (run-with-timeout (λ () 1) (λ (result) (and (= result 1) 7)) 0.1) 7)
  ;; +--- get-rankings ---+
  (check-equal? (get-rankings '() (list BLACK WHITE RED)) '())
  (check-equal? (get-rankings (state-players test-state) '())
                (reverse (state-players test-state)))
  (check-equal? (get-rankings (state-players test-state) (list BLACK))
                (list (make-player WHITE 2 (list (make-posn 2 0) (make-posn 0 2)))
                      (make-player RED 0 (list (make-posn 0 0) (make-posn 1 1))))))
