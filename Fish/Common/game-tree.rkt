#lang racket/base

(require racket/contract
         racket/list
         racket/local
         "state.rkt"
         "penguin-color.rkt")

(provide ;(contract-out [game? (-> any/c boolean?)])
         ;(contract-out [end-game? (-> any/c boolean?)])
         ;(contract-out [game-tree? (-> any/c boolean?)])
         (struct-out game)
         (struct-out end-game)
         is-valid-move?
         create-game
         apply-move
         all-possible-moves)

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct game [state player-turn kicked] #:transparent)
(define-struct end-game [state kicked] #:transparent)
(define game-tree? (or/c game? end-game?))
;; A GameTree is one of:
;; - Game
;; - EndGame
;; and represents a node in a game tree with some or no remaining moves.

;; A Game is a (make-game state? penguin-color? (listof? penguin-color?))
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

;; create-game : state? -> game-tree?
;; Creates a game with the provided state
;; NOTES:
;; - If there are no possible moved in the state, an end-game is returned with the state finalized
;; - The current player of the returned game is the first player in the list of players that can move
;; - Games start with no kicked players
(define (create-game state)
  (if (can-any-move? state)
      ;; Sets current to the first player in the list who has a valid move
      (make-game state (next-turn state (player-color (last (state-players state)))) '())
      (make-end-game (finalize-state state) '())))

;; is-valid-move? : game? move? -> boolean?
;; Is the given move (by the current player in the provided game) valid?
(define (is-valid-move? game move)
  (is-move-valid? (game-player-turn game) (move-from move) (move-to move) (game-state game)))

;; apply-move : game? move? -> game-tree?
;; Creates the next game state for a given valid move by the current player in the provided game
;; IMPORTANT: is-valid-move? should be queried prior to calling apply-move without exception handling
;; NOTES:
;; - Constructs an end-game if the resultant state has no valid moves
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

;; all-possible-moves : game? -> (hash/c move? game-tree?)
;; Builds a mapping of valid moves to their resulting game when applied to the given game
(define (all-possible-moves game)
  (define current-state (game-state game))
  (define current-player (get-player (game-player-turn game) current-state))

  (for*/hash ([from-posn (player-places current-player)]
              [to-posn (valid-moves from-posn current-state)]
              [move (in-value (make-move from-posn to-posn))])
    (values move (apply-move game move))))

;; kick-player : game? -> game-tree?
;; Kicks the current player from the game
(define (kick-player game)
  (define kick-color (game-player-turn game))
  (define new-state (remove-player-penguins (game-state game) kick-color))
  (define kicked-list (cons kick-color (game-kicked game)))
  
  (if (can-any-move? new-state)
      (make-game new-state
                 (next-turn new-state (player-color (last (state-players new-state))))
                 kicked-list)
      (make-end-game (finalize-state new-state) kicked-list)))

;; apply-to-all-children : game? (-> game-tree? any/c) -> (list-of any/c)
;; Applies the provided function to all child GameTrees of the given game
(define (apply-to-all-children game fn)
  (map fn (hash-values (all-possible-moves game))))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; next-turn : state? penguin-color? -> penguin-color?
;; Determines the color of the next player in the game, skipping players who cannot move
(define (next-turn state starting)
  (local [;; next-turn-h : state? penguin-color? -> penguin-color?
          ;; Recursively query until player with color current has valid moves in state
          (define (next-turn-h state current)
            (define next-color (get-next-color (state-players state) current))
            (if (can-color-move? next-color state)
                next-color
                (if (penguin-color=? next-color starting)
                    (raise-arguments-error 'next-turn "State has no valid moves" "state" state)
                    (next-turn-h state next-color))))]
    (next-turn-h state starting)))

;; get-next-color : (list-of player?) penguin-color? -> penguin-color?
;; Get the color of the player in the list after the player with the current color
(define (get-next-color order current)
  (define current-index (index-of (map player-color order) current penguin-color=?))
  (player-color (list-ref order (modulo (add1 current-index) (length order)))))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require lang/posn
           racket/set
           rackunit
           "board.rkt")

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
  ;; valid state, first player can move
  (define cg-state-ex1 (make-state (make-even-board 3 3 1)
                                   (list (make-player RED 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 2 2))))))
  (check-equal? (create-game cg-state-ex1) (make-game cg-state-ex1 RED '()))
  
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
                (make-end-game (finalize-state cg-state-ex2) '()))
  (check-equal? (create-game cg-state-ex3)
                (make-end-game (finalize-state cg-state-ex3) '()))
  ;; valid state, some players can't move
  (define cg-state-ex4 (make-state (make-even-board 2 2 1)
                                   (list (make-player RED 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 1 0)))
                                         (make-player BROWN 0 (list (make-posn 0 1))))))
  (define cg-state-ex5 (make-state (make-even-board 2 2 1)
                                   (list (make-player RED 0 (list (make-posn 0 0)))
                                         (make-player BLACK 0 (list (make-posn 0 1)))
                                         (make-player BROWN 0 (list (make-posn 1 0))))))
  (check-equal? (create-game cg-state-ex4)
                (make-game cg-state-ex4
                           BLACK
                           '()))
  (check-equal? (create-game cg-state-ex5)
                (make-game cg-state-ex5
                           BROWN
                           '()))

  ;; +--- is-valid-move? ---+
  (check-true (is-valid-move? test-game (make-move (make-posn 1 2) (make-posn 1 3))))
  (check-false (is-valid-move? test-game (make-move (make-posn 0 4) (make-posn 0 3))))

  ;; +--- apply-move ---+
  (check-exn exn:fail?
             (λ () (apply-move test-game (make-move (make-posn 0 4) (make-posn 0 3)))))
  ;; valid move, next player's turn
  (check-equal? (apply-move (make-game (make-state '((1 1 1 1 1))
                                                   (list (make-player BLACK 0 (list (make-posn 0 2)))
                                                         (make-player RED 0 (list (make-posn 0 0)))))
                                       BLACK '())
                            (make-move (make-posn 0 2) (make-posn 0 3)))
                (make-game (make-state '((1 1 0 1 1))
                                       (list (make-player BLACK 1 (list (make-posn 0 3)))
                                             (make-player RED 0 (list (make-posn 0 0)))))
                           RED
                           '()))
  ;; valid move, no other players have turn, comes back to current player
  (check-equal? (apply-move (make-game (make-state '((1 1 1 1 1))
                                                   (list (make-player BLACK 0 (list (make-posn 0 2)))
                                                         (make-player RED 0 (list (make-posn 0 0)))))
                                       BLACK '())
                            (make-move (make-posn 0 2) (make-posn 0 1)))
                (make-game (make-state '((1 1 0 1 1))
                                       (list (make-player BLACK 1 (list (make-posn 0 1)))
                                             (make-player RED 0 (list (make-posn 0 0)))))
                           BLACK
                           '()))
  ;; valid move, ends game
  (check-equal? (apply-move (make-game (make-state '((1 1 1 0 1))
                                                   (list (make-player BLACK 0 (list (make-posn 0 2)))
                                                         (make-player RED 0 (list (make-posn 0 0)))))
                                       BLACK '())
                            (make-move (make-posn 0 2) (make-posn 0 1)))
                (make-end-game (make-state '((0 0 0 0 1))
                                           (list (make-player BLACK 2 '())
                                                 (make-player RED 1 '())))
                               '()))

  ;; +--- all-possible-moves ---+
  (check-equal? (list->set (hash-keys (all-possible-moves test-game)))
                (set (make-move (make-posn 1 2) (make-posn 0 0))
                     (make-move (make-posn 1 2) (make-posn 0 1))
                     (make-move (make-posn 1 2) (make-posn 1 0))
                     (make-move (make-posn 1 2) (make-posn 1 3))
                     (make-move (make-posn 1 2) (make-posn 2 4))
                     (make-move (make-posn 2 3) (make-posn 2 4))
                     (make-move (make-posn 2 3) (make-posn 2 2))))
  (check-equal? (all-possible-moves
                 (make-game (make-state '((1 1 1 0 1))
                                        (list (make-player BLACK 0 (list (make-posn 0 2)))
                                              (make-player RED 0 (list (make-posn 0 0)))))
                            BLACK '()))
                (hash (make-move (make-posn 0 2)
                                 (make-posn 0 1))
                      (make-end-game (make-state '((0 0 0 0 1))
                                                 (list (make-player BLACK 2 '())
                                                       (make-player RED 1 '()))) '())
                      (make-move (make-posn 0 2) (make-posn 0 4))
                      (make-game (make-state '((1 1 0 0 1))
                                             (list (make-player BLACK 1 (list (make-posn 0 4)))
                                                   (make-player RED 0 (list (make-posn 0 0)))))
                                 RED '())))
  
  ;; +--- kick-player ---+
  ;; kick a player while another player who can play remains
  (check-equal?
   (kick-player test-game)
   (make-game
    (make-state '((1 3 0 1 3) (1 0 1 2 4) (2 0 2 3 5))
                (list (make-player BLACK 8 (list (make-posn 0 3) (make-posn 1 4) (make-posn 2 0)))
                      (make-player RED 3 '())
                      (make-player WHITE 6 '())))
    BLACK
    (list WHITE RED)))
  ;; kick all remaining players
  (check-equal?
   (kick-player (kick-player test-game))
   (make-end-game
    (make-state '((1 3 0 1 3) (1 0 1 2 4) (2 0 2 3 5))
                (list (make-player BLACK 8 '())
                      (make-player RED 3 '())
                      (make-player WHITE 6 '())))
    (list BLACK WHITE RED)))
  ;; kick remaining player who can move
  (check-equal?
   (kick-player (make-game (make-state '((1 1 0 0 1))
                                       (list (make-player RED 0 (list (make-posn 0 0)))
                                             (make-player BLACK 0 (list (make-posn 0 4)))))
                           RED '()))
   (make-end-game (make-state '((1 1 0 0 0)) (list (make-player RED 0 '()) (make-player BLACK 1 '())))
                  (list RED)))
  ;; +--- apply-to-all-children ---+
  ;; In one state, WHITE will move into the position BLACK is attempting to move into using the λ
  ;; The resulting list should state that the move is legal for BLACK in all but one case
  (check-equal? (sort (apply-to-all-children
                       test-game
                       (λ (gametree) (if (end-game? gametree)
                                         (error "No terminal games should exist")
                                         (is-valid-move? gametree (make-move (make-posn 1 4)
                                                                             (make-posn 1 3))))))
                      (λ (b1 b2) b1))
                (list #t #t #t #t #t #t #f))
  ;; In this Game, BLACK has two moves available. One of them will end the game, and in the other
  ;; BLACK can move again
  (check-equal? (sort
                 (apply-to-all-children
                  (make-game (make-state '((1 1 1 0 1))
                                         (list (make-player BLACK 0 (list (make-posn 0 2)))
                                               (make-player RED 0 (list (make-posn 0 0)))))
                             BLACK '())
                  end-game?)
                 (λ (b1 b2) b1))
                (list #t #f))
  
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
