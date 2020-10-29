#lang racket/base

(require racket/contract
         racket/list
         racket/local
         racket/promise
         "state.rkt"
         "penguin-color.rkt")

; TODO clean up
(provide (contract-out [game-tree? (-> any/c boolean?)])
         (struct-out game)
         (struct-out end-game)
         create-game
         (contract-out
          [apply-to-all-children (-> game? (-> game-tree? any/c) (hash/c move? any/c))]))

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct game [state player-turn children] #:transparent)
(define-struct end-game [state] #:transparent)
(define game-tree? (or/c game? end-game?))
;; TODO Clean up
;; A GameTree is one of:
;; - (make-end-game state? (listof? penguin-color?)])
;; - (make-game state? penguin-color? (promise? (hash/c move? game-tree?)))
;; and represents a game tree with either no moves or some remaining moves.

;; A Game is a (make-game state? penguin-color? (promise? (hash/c move? GameTree)))
;; and represents a node in a game tree with a state, a current player, and a list of kicked players.
;;
;; The current player (game-player-turn) is guaranteed to have one or more valid moves remaining.
;; If a player makes a move and the next player(s) are unable to move, players will be skipped until
;; a player with moves remaining is selected as the current player.
;; The application of any move to a Game that creates a state where no further moves are possible will
;; create an EndGame.
;; INVARIANT: All Games have at least one valid move for the current player.

;; An EndGame is a (make-end-game state? (listof? penguin-color?)])
;; and represents a terminal GameTree with a state and a list of kicked players.
;;
;; EndGames are created from states in which no valid move is remaining for any player, and the
;; EndGame itself will be finalized such that all remaining penguins are removed from the board and
;; the fish on the tiles they occupied will be added to their players' scores.
;; INVARIANT: EndGames have no penguins placed on the board.


;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : state? (penguin-color?) -> game-tree?
;; Creates a game with the provided state
;; NOTES:
;; - If there are no possible moved in the state, an end-game is returned with the state finalized
;; - The current player of the returned game is the first player in the list of players that can move
;; - Games start with no kicked players
;; - TODO
(define (create-game state [previous-player (player-color (last (state-players state)))])
  (if (can-any-move? state)
      (let ([current-player (next-turn state previous-player)])
        (make-game state current-player (delay (all-possible-moves state current-player))))
      (make-end-game (finalize-state state))))

;; apply-to-all-children : game? (-> game-tree? any/c) -> (hash-of move? any/c)
;; Applies the provided function to all child GameTrees of the given game
(define (apply-to-all-children game fn)
  (for/hash ([(move game) (in-hash (force (game-children game)))])
    (values move (fn game))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; all-possible-moves : state? penguin-color? -> (hash/c move? game-tree?)
;; Builds a mapping of valid moves to their resulting game trees from the given state and player
(define (all-possible-moves state current-player)
  (for*/hash ([from-posn (player-places (get-player current-player state))]
              [to-posn (valid-moves from-posn state)]
              [move (in-value (make-move from-posn to-posn))])
    (values move (apply-move state current-player move))))

;; apply-move : state? penguin-color? move? -> game-tree?
;; Creates the next game state for a given valid move by the current player in the provided game
;; IMPORTANT: is-move-valid? should be queried prior to calling apply-move without exception handling
;; NOTES:
;; - MOVE IS VALID TODO SAY BETTER
;; - Constructs an end-game if the resultant state has no valid moves
;; - Skips the turns of players who cannot move
(define (apply-move state current-player move)
  (define next-state (move-penguin current-player (move-from move) (move-to move) state))
  (if (can-any-move? next-state)
      (create-game next-state current-player)
      (make-end-game (finalize-state next-state))))

;; game-tree=? : game-tree? game-tree? -> bool?
;; Are the given game trees equal?
(define (game-tree=? gt1 gt2)
  (or (and (end-game? gt1)
           (end-game? gt2)
           (equal? (end-game-state gt1) (end-game-state gt2)))
      (and (game? gt1)
           (game? gt2)
           (equal? (game-state gt1) (game-state gt2))
           (equal? (game-player-turn gt1) (game-player-turn gt2)))))

;; next-playable-state : state? -> state?
;; Determines the next state, skipping players who are unable to move
;; NOTE: Must take a state with at least one player who can move
(define (next-playable-state state)
  (local [;; next-turn-h : state? penguin-color? -> penguin-color?
          ;; Recursively query until state where current player can play is reached
          (define (next-playable-state-h current)
            (define next-state (skip-player current))
            (if (can-current-move? next-state)
                next-state
                (if (equal? current state)
                    (raise-arguments-error
                     'next-playable-state "No players in state can move" "state" state)
                    (next-turn-h current))))]
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
            (make-player WHITE 6 (list (make-posn 0 4) (make-posn 1 2) (make-posn 2 3)))))
     BLACK))
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
  (check-equal? (game-player-turn (create-game cg-state-ex1)) RED)
  
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
  (check-equal? (game-player-turn (create-game cg-state-ex4)) BLACK)
  (check-equal? (game-player-turn (create-game cg-state-ex5)) BROWN)
  
  ;; +--- apply-move ---+
  ;; valid move, next player's turn
  (check-equal?
   (game-state (apply-move (make-state '((1 1 1 1 1))
                                       (list (make-player BLACK 0 (list (make-posn 0 2)))
                                             (make-player RED 0 (list (make-posn 0 0)))))
                           BLACK
                           (make-move (make-posn 0 2) (make-posn 0 3))))
   (game-state(create-game (make-state '((1 1 0 1 1))
                                       (list (make-player BLACK 1 (list (make-posn 0 3)))
                                             (make-player RED 0 (list (make-posn 0 0)))))
                           RED)))
  ;; valid move, no other players have turn, comes back to current player
  (check game-tree=?
         (apply-move (make-state '((1 1 1 1 1))
                                 (list (make-player BLACK 0 (list (make-posn 0 2)))
                                       (make-player RED 0 (list (make-posn 0 0)))))
                     BLACK
                     (make-move (make-posn 0 2) (make-posn 0 1)))
         (create-game (make-state '((1 1 0 1 1))
                                  (list (make-player BLACK 1 (list (make-posn 0 1)))
                                        (make-player RED 0 (list (make-posn 0 0)))))
                      BLACK))
  ;; valid move, ends game
  (check game-tree=?
         (apply-move (make-state '((1 1 1 0 1))
                                 (list (make-player BLACK 0 (list (make-posn 0 2)))
                                       (make-player RED 0 (list (make-posn 0 0)))))
                     BLACK
                     (make-move (make-posn 0 2) (make-posn 0 1)))
         (make-end-game (make-state '((0 0 0 0 1))
                                    (list (make-player BLACK 2 '())
                                          (make-player RED 1 '())))))

  ;; +--- all-possible-moves ---+
  (check-equal? (list->set (hash-keys (all-possible-moves (game-state test-game)
                                                          (game-player-turn test-game))))
                (set (make-move (make-posn 1 2) (make-posn 0 0))
                     (make-move (make-posn 1 2) (make-posn 0 1))
                     (make-move (make-posn 1 2) (make-posn 1 0))
                     (make-move (make-posn 1 2) (make-posn 1 3))
                     (make-move (make-posn 1 2) (make-posn 2 4))
                     (make-move (make-posn 2 3) (make-posn 2 4))
                     (make-move (make-posn 2 3) (make-posn 2 2))))
  (check-true
   (let ([hash-actual
          (all-possible-moves
           (make-state '((1 1 1 0 1))
                       (list (make-player BLACK 0 (list (make-posn 0 2)))
                             (make-player RED 0 (list (make-posn 0 0)))))
           BLACK)]
         [hash-expected
          (hash (make-move (make-posn 0 2)
                           (make-posn 0 1))
                (make-end-game (make-state '((0 0 0 0 1))
                                           (list (make-player BLACK 2 '())
                                                 (make-player RED 1 '()))))
                (make-move (make-posn 0 2) (make-posn 0 4))
                (create-game (make-state '((1 1 0 0 1))
                                         (list (make-player BLACK 1 (list (make-posn 0 4)))
                                               (make-player RED 0 (list (make-posn 0 0)))))
                             RED))])
     (andmap (λ (move)
               (game-tree=? (hash-ref hash-actual move) (hash-ref hash-expected move)))
             (append (hash-keys hash-expected) (hash-keys hash-actual)))))

  ;; +--- apply-to-all-children ---+
  ;; In one state, WHITE will move into the position BLACK is attempting to move into using the λ
  ;; The resulting list should state that the move is legal for BLACK in all but one case
  (check-equal? (apply-to-all-children
                 test-game
                 (λ (gametree) (if (end-game? gametree)
                                   (error "No terminal games should exist")
                                   (is-move-valid? (game-player-turn gametree)
                                                   (make-posn 1 4)
                                                   (make-posn 1 3)
                                                   (game-state gametree)))))
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
  ;; wrap around the end of the list
  (check-equal? (next-turn (game-state test-game) (game-player-turn test-game)) BLACK)
  ;; skip a kicked player
  (check-equal? (next-turn (game-state test-game) BLACK) WHITE)
  ;; skip a player with no moves
  (check-equal? (next-turn (make-state '((1 1) (1 1))
                                       (list (make-player WHITE 0 (list (make-posn 0 1)
                                                                        (make-posn 1 0)))
                                             (make-player RED 0 (list (make-posn 0 0)))))
                           WHITE)
                WHITE)
  ;; no possible moves would cause an error
  (check-exn exn:fail?
             (λ () (next-turn (make-state '((1 1) (0 0))
                                          (list (make-player WHITE 0 (list (make-posn 0 0)))
                                                (make-player RED 0 (list (make-posn 0 1)))))
                              WHITE)))
  
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
                RED))
