#lang racket/base

(require racket/contract
         racket/list
         racket/local
         "state.rkt"
         "penguin.rkt")

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
;; INVARIANT: All GameNodes that are make-games have at least one valid move for the current player

;; and represents a node in a GameTree.
;; GameNodes that are terminal (leaves of the tree) are represented as make-end-games.
;; GameNodes that have any number of moves that can be performed are represented as make-games, and
;; the current player, which can be accessed with game-player-turn, is guaranteed to have at least
;; one valid move.
;; If a player makes a move and the next player has no remaining moves, the next player is skipped
;; and the player after that player is checked, un

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : state? -> game-node?
;; Creates a game with the provided state, where the current player is the first player in the state
;; and there are no kicked players
(define (create-game state)
  (if (can-any-move? state)
      ;; Sets current to the first player in the list who has a valid move
      (make-game state (next-turn state (last (state-players state))) '())
      (make-end-game state '())))

;; is-valid-move? : game? move? -> boolean?
;; Is the given move (by the current player in the provided game) valid?
(define (is-valid-move? game move)
  (is-move-valid? (game-player-turn game) (move-from move) (move-to move) (game-state game)))

;; apply-move : game? move? -> game-node?
;; Creates the next game state for a given valid move by the current player in the provided game
;; IMPORTANT: is-valid-move? should be queried prior to calling apply-move without exception handling
;; NOTES:
;; - Constructs an end-game if the resultant Game has no valid moves
;; - Skips the turns of players who cannot move
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
;; Builds a mapping of valid moves to their resulting game when applied to the given game
(define (all-possible-moves game)
  (define current-state (game-state game))
  (define current-player (get-player (game-player-turn game) current-state))

  (for*/hash (;; Iterate over all posns the current player has penguins at
              [from-posn (player-places current-player)]
              ;; Iterate over all locations to which the current player can make a valid move
              [to-posn (valid-moves from-posn current-state)]
              ;; Bind the move and skip it if invalid
              [potential-move (in-value (make-move from-posn to-posn))]
              #:when (is-valid-move? game potential-move))
    (values potential-move (apply-move game potential-move))))

;; kick-player : game? -> game-node?
;; Kicks the current player from the game
(define (kick-player game)
  (define kick-color (game-player-turn game))
  (define new-state (remove-player-penguins (game-state game) kick-color))
  (define kicked-list (cons kick-color (game-kicked game)))
  
  (if (can-any-move? new-state)
      (make-game new-state (next-turn new-state (last (state-players new-state))) kicked-list)
      (make-end-game (finalize-state new-state kicked-list))))

;; apply-to-all-children : game? [game-node? -> any/c] -> [list-of any/c]
;; Applies the provided function to all child GameNodes of the given game
(define (apply-to-all-children game fn)
  (map fn (hash-values (all-possible-moves game))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; next turn : state? penguin? -> penguin?
;; Determines the color of the next player in the game, skipping players who cannot move
(define (next-turn state current)
  (local [;; next-turn-h : state? penguin? penguin? -> penguin?
          ;; Recursively query until player with color current has valid moves in state
          (define (next-turn-h state current original)
            (when (penguin=? current original)
              (raise-arguments-error 'next-turn "State has no valid moves" "state" state))
            (if (can-color-move? current state)
                current
                (next-turn-h state (get-next-color (state-players state) current) original)))]
    ;; Get the next color in the list, then recurively query until a color with valid moves is found
    (define next-color (get-next-color (state-players state) current))
    (next-turn-h state next-color current)))

;; get-next-color : (list-of player?) penguin? -> penguin?
;; Get the color of the player in the list after the player with the current color
(define (get-next-color order current)
  (define current-index (index-of (map player-color order) current penguin=?))
  (player-color (list-ref order (modulo (add1 current-index) (length order)))))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require rackunit
           lang/posn)

  (define test-game
    (make-game
     (make-state '((1 3 0 1 3) (1 0 1 2 4) (2 0 2 3 5))
                 (list (make-player BLACK 8 (list (make-posn 0 3) (make-posn 1 4) (make-posn 2 0)))
                       (make-player RED 3 '())
                       (make-player WHITE 6 (list (make-posn 0 4) (make-posn 1 2) (make-posn 2 3)))))
     WHITE
     (list RED)))
  (define test-end-game
    (make-end-game
     (make-state '((1 0 0 1 3) (0 0 1 0 4) (2 0 0 3 0))
                 (list (make-player BLACK 8 (list (make-posn 0 3) (make-posn 1 4) (make-posn 2 0)))
                       (make-player RED 3 '())
                       (make-player WHITE 6 (list (make-posn 0 4) (make-posn 1 2) (make-posn 2 3)))))
     (list RED)))

  ;; Provided Functions
  ;; +--- create-game ---+
  ;; +--- is-valid-move? ---+
  ;; +--- apply-move ---+
  ;; +--- all-possible-moves ---+x
  ;; +--- kick-player ---+
  ;; +--- apply-to-all-children ---+
  
  ;; Internal Helper Functions
  ;; +---- next-turn ---+
  ;; wrap around the end of the list
  (check-equal? (next-turn (game-state test-game) (game-player-turn test-game)) BLACK)
  ;; skip a kicked player
  (check-equal? (next-turn (game-state test-game) BLACK) WHITE)
  ;; skip a player with no moves
  (check-equal? (next-turn (make-state '((1 1) (1 1))
                                       (list (make-player WHITE 0 (list (make-posn 0 0)
                                                                        (make-posn 1 1)))
                                             (make-player RED 0 (list (make-posn 1 0)))))
                           WHITE)
                WHITE)
  
  ;; +--- get-next-color ---+
  (check-equal? (get-next-color (list (make-player RED 0 '())
                                      (make-player BROWN 0 '())
                                      (make-player BLACK 0 '()))
                                BROWN)
                BLACK)
  (check-equal? (get-next-color (list (make-player RED 0 '())
                                      (make-player BROWN 0 '())
                                      (make-player BLACK 0 '()))
                                BLACK)
                RED)
  )

;; TODO test create-game with blocked-in penguin at first of player list
