# Design Task
A referee manages a game of Fish for some set of players. The software component sets up the game, runs the rounds, and shuts down the game. It is the tournament administrator that sets up referees and players for games. See Fish.Com, a Plan.

Create a design document for the referee component, including its API. It should come with sufficient detail so that a sub-contractor in the far-away land of Codemanistan could implement it for you. In the meantime, you might be charged to implement a tournament manager.

Two pages should suffice. Less is more.

# Referee Component Spec
USE THE WORDS "OBSERVER PATTERN"
Describe how each function is called by the tournament manager

# Referee Interface

```racket
(define referee-interface
  (interface ()
    ;; create-game : (non-empty-list-of (is-a?/c player-interface?)) natural? natural? -> game-tree?
    ;; Inputs: list-of-players, num-rows, num-columns
    ;;
    ;; Notes: 2-4 players
    [create-game (->m (non-empty-list-of (is-a?/c player-interface?)) natural? natural? game-tee?)]
    
    ;; subscribe-as-game-observer : 
    [subscribe-as-game-observer (->m )]
    
    []))

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
;;   - represented by a start-event with the starting board and the starting list of player colors participating
;;     in the game.
;; - A player places a penguin
;;   - represented by a place-event, with a current state (after the placement), position the penguin was placed
;;     at, and color of the player who placed the penguin.
;; - A player moves a penguin
;;   - represented by a move-event, with a current game tree (after the move), the move that was made, and the
;;     color of the player who made the move.
;; - A player is kicked from the game
;;   - represented by a kick-event, with the current game tree (after the player has been kicked and their
;;     penguins removed), and the color of the penguin who was kicked.
;; - A game ends
;;   - represented by an end-event, with a final game node and a list of player colors that were kicked from
;;     the game.

(define game-observer-interface
  (interface ()
    ;; observe : fish-game-event? -> void?
    ;; Observes the FishGameEvent. The implementer can decide if and how this information is relevant to them.
    ;; Notes:
    ;; - Called by the Referee on all observers each time any FishGameEvent occurs.
    [observe (->m fish-game-event? void?)]))
    
```

## Functions
 1. `create-game`
 A referee supervises an individual game after being handed a number of players. The referee sets up a board...
 
 2. `subscribe-as-game-observer`
 during the game it may need to inform game observers of on-going actions.
 
 3. `run-game` : -> (list/c end-game? (list-of player?))
 ...and interacts with the players according to the interface protocol. It removes a player—really its penguins—that fails or cheats. When the game is over, it reports the outcome of the game and the failing and cheating players;

# Referee Protocol
