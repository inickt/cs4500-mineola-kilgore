#lang racket/base

(require racket/contract
         racket/list
         racket/local
         racket/promise
         "state.rkt"
         "penguin-color.rkt")

(provide (contract-out [game-tree? (-> any/c boolean?)])

         (contract-out [game? (-> any/c boolean?)])
         (contract-out [game-state (-> game? state?)])
         (contract-out [game-children (-> game? (promise/c (hash/c move? game-tree?)))])

         (contract-out [end-game? (-> any/c boolean?)])
         (contract-out [end-game-state (-> end-game? state?)])

         (contract-out [create-game (-> state? game-tree?)])
         (contract-out [apply-to-all-children (-> game? (-> game-tree? any/c) (hash/c move? any/c))]))

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct game [state children] #:transparent)
(define-struct end-game [state] #:transparent)
(define game-tree? (or/c game? end-game?))

;; A GameTree is one of:
;; - EndGame
;; - Game
;; and represents a game tree with either no moves or some remaining moves.

;; An EndGame is a (make-end-game state?])
;; and represents a terminal GameTree with a final state.
;;
;; EndGames are created from states in which no valid move is remaining for any player, and the
;; EndGame itself will be finalized such that all remaining penguins are removed from the board and
;; the fish on the tiles they occupied will be added to their players' scores.
;; INVARIANT: EndGames have no penguins placed on the board.

;; A Game is a (make-game state? (promise? (hash/c move? game-tree?)))
;; and represents a node in a game tree with a state, a current player, and a list of kicked players.
;;
;; The current player (game-player-turn) is guaranteed to have one or more valid moves remaining.
;; If a player makes a move and the next player(s) are unable to move, players will be skipped until
;; a player with moves remaining is selected as the current player.
;; The application of any move to a Game that creates a state where no further moves are possible will
;; create an EndGame.
;; INVARIANT: All Games have at least one valid move for the current player.

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : state? (penguin-color?) -> game-tree?
;; Creates a game with the provided state
;; NOTES:
;; - If there are no possible moved in the state, an end-game is returned with the state finalized
;; - The current player of the returned game is the first player in the list of players that can move
;; - Games start with no kicked players
(define (create-game state)
  (if (can-any-move? state)
      (let ([next-state (next-playable-state state)])
        (make-game next-state (delay (all-possible-moves next-state))))
      (make-end-game (finalize-state state))))

;; apply-to-all-children : game? (-> game-tree? any/c) -> (hash-of move? any/c)
;; Applies the provided function to all child GameTrees of the given game
(define (apply-to-all-children game fn)
  (for/hash ([(move game) (in-hash (force (game-children game)))])
    (values move (fn game))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; all-possible-moves : state? -> (hash/c move? game-tree?)
;; Builds a mapping of valid moves to their resulting game trees from the given state
(define (all-possible-moves state)
  (for*/hash ([from-posn (player-places (state-current-player state))]
              [move (valid-moves state from-posn)])
    (values move (apply-move state move))))

;; apply-move : state? move? -> game-tree?
;; Creates the next game state for a given valid move by the current player in the provided game
;; IMPORTANT: is-move-valid? should be queried prior to calling apply-move without exception handling
;; NOTES:
;; - The provided move must be valid for the given state
;;   - both FROM and TO positions are valid Tiles on the board
;;   - a penguin of the current player's color exists at the FROM position
;;   - there is a path from the FROM position the TO position that is not blocked by holes or penguins
;; - Constructs an end-game if the resultant state has no valid moves
;; - Skips the turns of players who cannot move
(define (apply-move state move)
  (define next-state (move-penguin state move))
  (if (can-any-move? next-state)
      (create-game next-state)
      (make-end-game (finalize-state next-state))))

;; game-tree=? : game-tree? game-tree? -> bool?
;; Are the given game trees equal?
(define (game-tree=? gt1 gt2)
  (or (and (end-game? gt1)
           (end-game? gt2)
           (equal? (end-game-state gt1) (end-game-state gt2)))
      (and (game? gt1)
           (game? gt2)
           (equal? (game-state gt1) (game-state gt2)))))

;; next-playable-state : state? -> state?
;; Skips to the next state in which the current player can move, or the given state if current can
;; already move
;; NOTE: Must take a state with at least one player who can move
(define (next-playable-state state)
  (local [;; next-turn-h : state? penguin-color? -> penguin-color?
          ;; Recursively query until state where current player can play is reached
          (define (next-playable-state-h current)
            (if (can-color-move? current (player-color (state-current-player current)))
                current
                (let
                    ([next-state (skip-player current)])
                  (if (equal? next-state state)
                      (raise-arguments-error
                       'next-playable-state "No players in state can move" "state" state)
                      (next-playable-state-h next-state)))))]
    (next-playable-state-h state)))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require lang/posn
           racket/set
           rackunit
           "board.rkt")

  (define test-game
    (create-game
     (make-state
      '((1 3 0 1 3) (1 0 1 2 4) (2 0 2 3 5))
      (list (make-player BLACK 8 (list (make-posn 0 3) (make-posn 1 4) (make-posn 2 0)))
            (make-player RED 3 '())
            (make-player WHITE 6 (list (make-posn 0 4) (make-posn 1 2) (make-posn 2 3)))))))
  (define test-end-game
    (make-end-game
     (make-state
      '((1 0 0 1 3) (0 0 1 0 4) (2 0 0 3 0))
      (list (make-player BLACK 8 (list (make-posn 0 3) (make-posn 1 4) (make-posn 2 0)))
            (make-player RED 3 '())
            (make-player WHITE 6 (list (make-posn 0 4) (make-posn 1 2) (make-posn 2 3)))))))

  ;; Provided Functions
  ;; +--- create-game ---+
  ;; valid state, first player can move
  (define cg-state-ex1 (make-state (make-even-board 3 3 1)
                                   (list (make-player RED 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 2 2))))))
  (check-equal? (player-color (state-current-player (game-state (create-game cg-state-ex1)))) RED)
  (check-equal?
   (for/hash
       ([(move child)
         (in-hash
          (force (game-children
                  (create-game (make-state '((1 2 1 0))
                                           (list (make-player BLACK 0 (list (make-posn 0 0)))))))))])
     (values move (game-state child)))
   (hash (make-move (make-posn 0 0) (make-posn 0 1))
         (make-state '((0 2 1 0)) (list (make-player BLACK 1 (list (make-posn 0 1)))))
         (make-move (make-posn 0 0) (make-posn 0 2))
         (make-state '((0 2 1 0)) (list (make-player BLACK 1 (list (make-posn 0 2)))))))
  ;; none can move
  (define cg-state-ex2 (make-state (make-even-board 1 2 1)
                                   (list (make-player BROWN 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 0 1))))))
  (define cg-state-ex3 (make-state (make-even-board 2 2 1)
                                   (list (make-player RED 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 0 1)))
                                         (make-player BROWN 0 (list (make-posn 1 0)))
                                         (make-player WHITE 0 (list (make-posn 1 1))))))
  (check-equal? (create-game cg-state-ex2)
                (make-end-game (finalize-state cg-state-ex2)))
  (check-equal? (create-game cg-state-ex3)
                (make-end-game (finalize-state cg-state-ex3)))
  ;; valid state, some players can't move
  (define cg-state-ex4 (make-state (make-even-board 2 2 1)
                                   (list (make-player RED 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 1 0)))
                                         (make-player BROWN 0 (list (make-posn 0 1))))))
  (define cg-state-ex5 (make-state (make-even-board 2 2 1)
                                   (list (make-player RED 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 0 1)))
                                         (make-player BROWN 0 (list (make-posn 1 0))))))
  (check-equal? (player-color (state-current-player (game-state (create-game cg-state-ex4)))) BLACK)
  (check-equal? (player-color (state-current-player (game-state (create-game cg-state-ex5)))) BROWN)
  
  ;; +--- apply-move ---+
  ;; valid move, next player's turn
  (check-equal?
   (game-state (apply-move (make-state '((1 1 1 1 1))
                                       (list (make-player BLACK 0 (list (make-posn 0 2)))
                                             (make-player RED 0 (list (make-posn 0 0)))))
                           (make-move (make-posn 0 2) (make-posn 0 3))))
   (game-state (create-game (make-state '((1 1 0 1 1))
                                        (list (make-player RED 0 (list (make-posn 0 0)))
                                              (make-player BLACK 1 (list (make-posn 0 3))))))))
  ;; valid move, no other players have turn, comes back to current player
  (check game-tree=?
         (apply-move (make-state '((1 1 1 1 1))
                                 (list (make-player BLACK 0 (list (make-posn 0 2)))
                                       (make-player RED 0 (list (make-posn 0 0)))))
                     (make-move (make-posn 0 2) (make-posn 0 1)))
         (create-game (make-state '((1 1 0 1 1))
                                  (list (make-player BLACK 1 (list (make-posn 0 1)))
                                        (make-player RED 0 (list (make-posn 0 0)))))))
  ;; valid move, ends game
  (check game-tree=?
         (apply-move (make-state '((1 1 1 0 1))
                                 (list (make-player BLACK 0 (list (make-posn 0 2)))
                                       (make-player RED 0 (list (make-posn 0 0)))))
                     (make-move (make-posn 0 2) (make-posn 0 1)))
         (make-end-game (make-state '((0 0 0 0 1))
                                    (list (make-player RED 1 '())
                                          (make-player BLACK 2 '())))))

  ;; +--- all-possible-moves ---+
  (check-equal? (list->set (hash-keys (all-possible-moves (game-state test-game))))
                (set (make-move (make-posn 0 3) (make-posn 0 1))
                     (make-move (make-posn 1 4) (make-posn 1 3))
                     (make-move (make-posn 1 4) (make-posn 2 2))
                     (make-move (make-posn 2 0) (make-posn 2 2))
                     (make-move (make-posn 2 0) (make-posn 2 4))))
  (check-true
   (let ([hash-actual
          (all-possible-moves
           (make-state '((1 1 1 0 1))
                       (list (make-player BLACK 0 (list (make-posn 0 2)))
                             (make-player RED 0 (list (make-posn 0 0))))))]
         [hash-expected
          (hash (make-move (make-posn 0 2) (make-posn 0 1))
                (make-end-game (make-state '((0 0 0 0 1))
                                           (list (make-player RED 1 '())
                                                 (make-player BLACK 2 '()))))
                (make-move (make-posn 0 2) (make-posn 0 4))
                (create-game (make-state '((1 1 0 0 1))
                                         (list (make-player RED 0 (list (make-posn 0 0)))
                                               (make-player BLACK 1 (list (make-posn 0 4)))))))])
     (andmap (λ (move)
               (game-tree=? (hash-ref hash-actual move) (hash-ref hash-expected move)))
             (append (hash-keys hash-expected) (hash-keys hash-actual)))))

  ;; +--- apply-to-all-children ---+
  ;; In one state, WHITE will move into the position BLACK is attempting to move into using the λ
  ;; The resulting list should state that the move is legal for BLACK in all but one case
  (check-equal? (apply-to-all-children
                 (create-game (skip-player (game-state test-game)))
                 (λ (gametree) (if (end-game? gametree)
                                   (error "No terminal games should exist")
                                   (is-move-valid? (game-state gametree)
                                                   (make-move (make-posn 1 4) (make-posn 1 3))))))
                (hash (make-move (make-posn 1 2) (make-posn 1 3)) #f
                      (make-move (make-posn 1 2) (make-posn 0 0)) #t
                      (make-move (make-posn 1 2) (make-posn 0 1)) #t
                      (make-move (make-posn 1 2) (make-posn 1 0)) #t
                      (make-move (make-posn 1 2) (make-posn 2 4)) #t
                      (make-move (make-posn 2 3) (make-posn 2 2)) #t
                      (make-move (make-posn 2 3) (make-posn 2 4)) #t))
  
  ;; In this Game, BLACK has two moves available. One of them will end the game, and in the other
  ;; BLACK can move again
  (check-equal? (apply-to-all-children
                 (create-game (make-state '((1 1 1 0 1))
                                          (list (make-player BLACK 0 (list (make-posn 0 2)))
                                                (make-player RED 0 (list (make-posn 0 0))))))
                 end-game?)
                (hash (make-move (make-posn 0 2) (make-posn 0 1)) #t
                      (make-move (make-posn 0 2) (make-posn 0 4)) #f))
  
  ;; Internal Helper Functions
  ;; +---- next-turn ---+
  ;; return the unchanged state because the current player can play
  (check-equal? (next-playable-state (game-state test-game))
                (game-state test-game))
  ;; skip a player with no moves
  (check-equal? (next-playable-state (make-state '((1 1) (1 1))
                                                 (list (make-player WHITE 0 (list (make-posn 0 1)
                                                                                  (make-posn 1 0)))
                                                       (make-player RED 0 (list (make-posn 0 0))))))
                (make-state '((1 1) (1 1))
                            (list (make-player WHITE 0 (list (make-posn 0 1) (make-posn 1 0)))
                                  (make-player RED 0 (list (make-posn 0 0))))))
  ;; no possible moves would cause an error
  (check-exn exn:fail?
             (λ () (next-playable-state
                    (make-state '((1 1) (0 0))
                                (list (make-player WHITE 0 (list (make-posn 0 0)))
                                      (make-player RED 0 (list (make-posn 0 1)))))))))
