#lang racket/base

(require lang/posn
         racket/class
         racket/contract
         racket/engine
         racket/list
         racket/math
         racket/promise
         "../Common/board.rkt"
         "../Common/game-tree.rkt"
         "../Common/player-interface.rkt"
         "../Common/state.rkt"
         "../Player/player.rkt")

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

(define INIT-MAX-HOLE-RATIO 1/5)
(define TIMEOUT 10)

(define-struct start-event [board player-colors])
(define-struct place-event [state position color])
(define-struct move-event [game move color])
(define-struct kick-event [game kicked-player])
(define-struct end-event [game kicked-players])
(define fish-game-event? (or/c start-event?
                               place-event?
                               move-event?
                               kick-event?
                               end-event?))
;; A FishGameEvent is one of:
;; - (make-start-event board? (list-of penguin-color?))
;; - (make-place-event state? posn? penguin-color?)
;; - (make-move-event game-tree? move? penguin-color?)
;; - (make-kick-event game-tree? penguin-color?)
;; - (make-end-event end-game? (list-of penguin-color?))

;; A FishGameEvent represents an event occurring for a game of Fish.
;; There are 5 possible events:
;; - A game is begins
;;   - represented by a start-event with the starting board and the starting list of player colors
;;     participating in the game.
;; - A player places a penguin
;;   - represented by a place-event, with a current state (after the placement), position the penguin
;;     was placed at, and color of the player who placed the penguin.
;; - A player moves a penguin
;;   - represented by a move-event, with a current game tree (after the move), the move that was made,
;;     and the color of the player who made the move.
;; - A player is kicked from the game
;;   - represented by a kick-event, with the current game tree (after the player has been kicked and
;;     their penguins removed), and the color of the penguin who was kicked.
;; - A game ends
;;   - represented by an end-event, with a final game node and a list of player colors that were
;;     kicked from the game.

(define game-observer-interface
  (interface ()
    ;; observe : fish-game-event? -> void?
    ;; Observes the FishGameEvent. The implementer can decide if and how this information is relevant
    ;; Notes:
    ;; - Called by the Referee on all observers each time any FishGameEvent occurs.
    [observe (->m fish-game-event? void?)]))

(define referee-interface
  (interface ()
    ;; subscribe-as-game-observer : (is-a?/c game-observer-interface) -> boolean?
    ;; Inputs: observer
    ;;
    ;; The Tournament Manager will call this function with a game-observer that wishes to be informed
    ;; of FishGameEvents. The referee will then call the observer's observe function with all
    ;; FishGameEvent updates produced as the game of Fish is run.
    ;; Returns true when the subscription is successful.
    ;; 
    [subscribe-as-game-observer (->m (is-a?/c game-observer-interface) boolean?)]
    
    ;; remove-game-observer : (is-a?/c game-observer-interface) -> boolean?
    ;; Inputs: observer
    ;;
    ;; The Tournament Manager will call this function with a game-observer that wishes to be removed
    ;; from the list of observers and not receive any more FishGameEvent updates for this Referee's
    ;; games of Fish.
    ;; Returns true if the observer is successfully removed from the list, or false if the observer 
    ;; isn't found.
    ;;
    [remove-game-observer (->m (is-a?/c game-observer-interface) boolean?)]
    
    ;; run-game : (non-empty-list-of (is-a?/c player-interface?)) posint? posint?
    ;;             -> (list/c end-game? (is-a?/c player-interface))
    ;; Inputs: list-of-players, num-rows, num-columns
    ;;
    ;; When called by a Tournament Manager, causes the Referee to run a game of Fish.
    ;; The Referee determines the initial layout of the board, which will have a number of rows
    ;; specified by num-rows, and a number of columns specified by num-columns. The referee may remove
    ;; some tiles, creating holes on the initial board.
    ;; The Referee will then determine a play order, which starts with the player who's age is lowest
    ;; and cycles through the players in a round-robin fashion.
    ;; The Referee will call `get-placement` on each player 6 - N times, where N is the number of
    ;; players.
    ;; The Referee will then call `get-movement` on the current player of the GameTree until it
    ;; reaches an EndGame where there are no valid moves remaining.
    ;; If, during this process, a player fails to make a move or cheats, the Referee will kick the
    ;; player from the game and then resume the game without that player or it's penguins.
    ;; The Referee will finally return the EndGame and the list of players who were kicked.
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
                   (list/c end-game?
                           (non-empty-listof (list/c (is-a?/c player-interface) natural?))
                           (listof (is-a?/c player-interface))))]))


(define referee%
  (class* object% (referee-interface)
    (super-new)
    (define/public (subscribe-as-game-observer game-observer)
      (void))
    (define/public (remove-game-observer game-observer)
      (void))

    (define/public (run-game players num-cols num-rows)
      ; Board initialization
      (define init-board (create-initial-board num-cols num-rows (length players)))
      ; State initialization
      (define init-state (create-state (length players) init-board))
      (displayln (draw-state init-state 40))
      (define player-color-map (create-player-color-map players init-state))
      ;; Get placements
      (define state-with-placements (get-all-placements init-state player-color-map))
      (displayln (draw-state state-with-placements 40))
      ;; Get all moves
      (define-values (end-game kicked)
        (play-game (create-game state-with-placements) player-color-map))
      ; - assign players to colors from initial state based on order
      ; start placement
      ; - (6 - n) players
      ; - determine if all players are placed
      ; start movements
      ; - check validity
      ; - kick on invalid moves/timeout
      (displayln kicked)

      (list end-game
            (map (λ (player) (list player 0)) players)
            '()))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; create-player-color-map : (non-empty-listof (is-a?/c player-interface)) state?
;;                           -> (hash/c penguin-color? (is-a?/c player-interface))
;;
;; NOTE: Players and state players must be the same length
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
       (place-penguin state (send (get-player player-color-map state) get-placement state))
       player-color-map)))

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

;; play-game : game-tree? (hash-of penguin-color? (is-a?/c player-interface?)) (listof penguin-color?) -> end-game? (listof penguin-color?)
;; 
(define (play-game initial-game player-color-map)
  (let play ([game initial-game]
             [kicked '()])
    (displayln (draw-state ((if (end-game? game) end-game-state game-state) game) 40))
    (if (end-game? game)
        (values game kicked)
        (let ([player-color (player-color (state-current-player (game-state game)))]
              [maybe-game-tree (play-one-move game (get-player player-color-map (game-state game)))])
          (if (not maybe-game-tree)
              (play (kick-player game player-color) (cons player-color kicked))
              (play maybe-game-tree kicked))))))

;; play-one-move : game? (is-a?/c player-interface?) -> (or/c false? game-tree?)
;; Gets a player's move and applies it to the given game tree
;; NOTE: It must be the given player's turn in the provided game
;; 
(define (play-one-move game player)
  (define children (force (game-children game)))
  (define player-engine (engine (λ (_) (send player get-move game))))
  (with-handlers ([exn:fail? (λ (exn) #f)])
    (engine-run (* TIMEOUT 1000) player-engine)
    (hash-ref children (engine-result player-engine))))

;; kick-player : game? penguin-color -> game-tree?
(define (kick-player game penguin-color)
  (create-game (remove-penguins (game-state game) penguin-color)))



(define p1 (new player% [depth 2]))
(define p2 (new player% [depth 2]))
(define r (new referee%))




                         

