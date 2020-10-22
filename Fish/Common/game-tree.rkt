#lang racket/base

(require racket/contract
         racket/list
         "state.rkt")

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct move [from to])
;; A Move is a (make-move posn? posn?)
;; and represents a penguin move on a fish board

(define-struct game [state player-turn kicked] #:transparent)
(define-struct end-game [state kicked] #:transparent)
(define game-node? (or/c game? end-game?))
;; A GameNode is one of:
;; - (make-game state? penguin? (listof? penguin?))
;; - (make-end-game state? (listof? penguin?)])
;; TODO

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : state? -> game-node?
;; Creates a game with the provided state, where the current player is the first player in the state
;; and there are no kicked players
(define (create-game state)
  (make-game state (player-color (first (state-players state))) '()))

;; is-valid-move? : game? move? -> boolean?
;; Is the given move (by the current player in the provided game) valid?
(define (is-valid-move? game move)
  (is-move-valid? (game-player-turn game) (move-from move) (move-to move) (game-state game)))

;; apply-move : game? move? -> game-node?
;; Creates the next game state for a given valid move by the current player in the provided game
(define (apply-move game move)
  (when (not (is-valid-move? game move))
    (raise-arguments-error 'apply-move
                           "The move is not valid in the given game"
                           "move" move))
  (define current-player (game-player-turn game))
  (define kicked-players (game-kicked game))
  (define new-state (move-penguin current-player
                                  (move-from move)
                                  (move-to move)
                                  (game-state game)))
  (if (can-any-move? new-state)
      (make-game new-state (next-turn new-state current-player) kicked-players)
      (make-end-game (finalize-state new-state) kicked-players)))

;; all-possible-moves : game? -> (hash/c move? game-node?)
;;
(define (all-possible-moves game)
  ;; TODO put in apply-move PS
  ;; what to do about:
  ;; - end game?
  ;; - current player can't move?

  ;; TODO put in purpose statement
  ;; high level:
  ;; use posns of possible moves
  ;; for each posn call all possible moves
  ;; build up all move -> resulting game
  (define current-state (game-state game))
  (define current-player (get-player (game-player-turn game) current-state))

  (for*/hash ([from-posn (player-places current-player)]
              [to-posn (valid-moves from-posn current-state)]
              [potential-move (in-value (make-move from-posn to-posn))]
              #:when (is-valid-move? potential-move))
    (values potential-move (apply-move game potential-move))))

;; next turn : state? penguin? -> penguin?
;; 
(define (next-turn state current)
  (state-players state)

  ;; try next
  ;; if not kicked, if has moves return
  (define player-order (state-players state))
  (define current-index (index-of player-order current penguin=?))
  
  (for ([offset (sub1 (length player-order))])
    (define next-index (modulo (add1 current-index) offset (length player-order)))
    (define next-player (list-ref player-order next-index))
    
  
  ...))

;; TODO get-finalized-state

