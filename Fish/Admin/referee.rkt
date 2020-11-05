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
      (define state-with-placements (get-all-placements init-state player-color-map))
      
      (define-values (final-game kicked)
        (play-game (create-game state-with-placements) player-color-map))
      (define results (state-players (end-game-state final-game)))
      
      (list (map (λ (player) (list (hash-ref player-color-map (player-color player))
                                   (player-score player)))
                 (get-rankings results kicked))
            (map (λ (player) (hash-ref player-color-map player)) kicked)))))

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

;; get-all-placements : state? (hash-of penguin-color? (is-a?/c player-interface?)) -> state?
(define (get-all-placements state player-color-map)
  (if (all-penguins-placed? state)
      state
      (get-all-placements
       (get-single-placement state (get-player player-color-map state))
       player-color-map)))

;; get-single-placement : state? (is-a?/c player-interface?) -> state?
(define (get-single-placement state player)
  (run-with-timeout
   (λ () (send player get-placement state))
   (λ (result-posn) (place-penguin state result-posn))))

;; get-player :
;; (hash-of penguin-color? (is-a?/c player-interface?)) state? -> (is-a?/c player-interface?))
;; Gets the 
(define (get-player player-color-map state)
  (hash-ref player-color-map (player-color (state-current-player state))))

;; all-penguins-placed? : state? -> boolean?
;; Are all of the players penguins placed on the board?
(define (all-penguins-placed? state)
  (define num-penguins (penguins-per-player (length (state-players state))))
  (andmap (λ (player) (= (length (player-places player)) num-penguins)) (state-players state)))

;; penguins-per-player : posint? -> posint?
;; Determines the number of penguins per player
(define (penguins-per-player n) (- 6 n))

;; play-game : game-tree? (hash-of penguin-color? (is-a?/c player-interface?))
;;             -> end-game? (listof penguin-color?)
;; Plays a complete game of Fish by querying each player for its desired move.
;; NOTE: If a player cheats, or exceeds the timeout threshold for choosing a move, it is kicked from
;; the game, and the game continues with that player's penguins removed from the board.
(define (play-game initial-game player-color-map)
  (let play ([game initial-game]
             [kicked '()])
    (displayln (draw-state ((if (end-game? game) end-game-state game-state) game) 30))
    (if (end-game? game)
        (values game kicked)
        (let ([player-color (player-color (state-current-player (game-state game)))]
              [maybe-game-tree (play-one-move game (get-player player-color-map (game-state game)))])
          (if (not maybe-game-tree)
              (play (kick-player game player-color) (cons player-color kicked))
              (play maybe-game-tree kicked))))))

;; play-one-move : game? (is-a?/c player-interface?) -> (or/c false? game-tree?)
;; Gets a player's move and applies it to the given game tree
;; NOTES:
;; - It must be the given player's turn in the provided game
;; - If a player cheats or exceeds the timeout threshold returns false, else returns the new GameTree
(define (play-one-move game player)
  (define children (force (game-children game)))
  (run-with-timeout
   (λ () (send player get-move game))
   (λ (result-move) (hash-ref children result-move))))

;; kick-player : game? penguin-color -> game-tree?
;; Removes the player with the given color from the GameTree by removing their penguins
(define (kick-player game penguin-color)
  (create-game (remove-penguins (game-state game) penguin-color)))

;; run-with-timeout : (X Y) (-> X) (X -> Y) -> (or/c Y false?)
;; Runs run-proc for up to TIMEOUT seconds, then calls result-proc on the result value
;; Returns false if run-proc times out, or if either run-proc or result-proc error
(define (run-with-timeout run-proc result-proc)
  (define run-engine (engine (λ (_) (run-proc))))
  (with-handlers ([exn:fail? (λ (exn) #f)])
    (engine-run (* TIMEOUT 1000) run-engine)
    (result-proc (engine-result run-engine))))
  
;; get-rankings : (listof player?) (listof penguin-color?) -> (listof player? natural?)
;; Filters out kicked players and returns the list of players sorted in descending order by score
(define (get-rankings players kicked)
  (sort (filter (λ (player) (not (member (player-color player) kicked))) players)
        >
        #:key player-score))

(define p1 (new player% [depth 2]))
(define p2 (new player% [depth 2]))
(define r (new referee%))




                         

