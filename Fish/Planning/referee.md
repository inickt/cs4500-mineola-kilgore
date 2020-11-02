# Referee Interface

```racket
(define referee-interface
  (interface ()
    ;; subscribe-as-game-observer : (is-a?/c game-observer-interface) -> boolean?
    ;; Inputs: observer
    ;;
    ;; The Tournament Manager will call this function with a game-observer that wishes to be informed
    ;; of FishGameEvents. The referee will then call the observer's observe function with all FishGameEvent
    ;; updates produced as the game of Fish is run.
    ;; Returns true when the subscription is successful.
    ;; 
    [subscribe-as-game-observer (->m (is-a?/c game-observer-interface) boolean?)]
    
    ;; remove-game-observer : (is-a?/c game-observer-interface) -> boolean?
    ;; Inputs: observer
    ;;
    ;; The Tournament Manager will call this function with a game-observer that wishes to be removed
    ;; from the list of observers and not receive any more FishGameEvent updates for this Referee's
    ;; games of Fish.
    ;; Returns true if the observer is successfully removed from the list, or false if the observer isn't found.
    ;; 
    [remove-game-observer (->m (is-a?/c game-observer-interface) boolean?)]
    
    ;; run-game : (non-empty-list-of (is-a?/c player-interface?)) natural? natural? -> (list/c end-game? (is-a?/c player-interface))
    ;; Inputs: list-of-players, num-rows, num-columns
    ;;
    ;; When called by a Tournament Manager, causes the Referee to run a game of Fish.
    ;; The Referee determines the initial layout of the board, which will have a number of rows specified by
    ;; num-rows, and a number of columns specified by num-columns. The referee may remove some tiles,
    ;; creating holes on the initial board.
    ;; The Referee will then determine a play order, which starts with the player who's age is lowest and cycles
    ;; through the players in a round-robin fashion.
    ;; The Referee will call `get-placement` on each player 6 - N times, where N is the number of players.
    ;; The Referee will then call `get-movement` on the current player of the GameTree until it reaches an EndGame
    ;; where there are no valid moves remaining.
    ;; If, during this process, a player fails to make a move or cheats, the Referee will kick the player from
    ;; the game and then resume the game without that player or it's penguins.
    ;; The Referee will finally return the EndGame and the list of players who were kicked.
    ;;
    ;; For each step of the game for which a FishGameEvent can be produced (start, placement, move, kick, end),
    ;; the Referee will call observe once on each observer of the game and pass it the FishGameEvent.
    ;;
    ;; NOTE: The Tournament Manager must provide between 2 and 4 players, inclusive.
    ;;
    [run-game (->m (non-empty-list-of (is-a?/c player-interface?)) natural? natural? (list/c end-game? (is-a?/c player-interface)))]))

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
    ;; Observes the FishGameEvent. The implementer can decide if and how this information is relevant to it.
    ;; Notes:
    ;; - Called by the Referee on all observers each time any FishGameEvent occurs.
    [observe (->m fish-game-event? void?)]))
    
```


# Referee Protocol

## Functions
There are three functions a Tournament Manager will call on a Referee.

 - `subscribe-as-game-observer`
   - The referee implements the Observer Pattern by providing this function and `remove-game-observer`. The Tournament Manager will call `subscribe-as-game-observer` for each observer desiring to be subscribed to `FishGameEvent` updates for games of Fish this Referee manages, providing the observer to the Referee which will add it as an observer of the game of Fish. Any time an action occurs in any Fish game this Referee manages, each observer is notified by having its `observe` method called with the relevant FishGameAction.
 - `remove-game-observer`
   - The referee implements the Observer Pattern by providing this function and `subscribe-as-game-observer`. The Tournament Manager will call `remove-game-observer` once for each observer of a Referee desiring to be unsubscribed from `FishGameEvent` updates. The Referee will then cease to call it's `observe` method.
 - `run-game`
   - The Tournament Manager calls `run-game` on the Referee, providing a list of players as well as a number of rows and columns for the board. The Referee then runs a full game of Fish. It interacts with players according to the player protocol defined [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/jake/Fish/Planning/player-protocol.md). During the game, it informs game observers of any occurring FishGameActions. Any players who cheat or fail to play are kicked and its penguins removed from the game, and then the game is restarted without that player. When finished, the Referee returns the final `EndGame` produced, as well as a list of players who were kicked from the game for cheating or failing to play.

## Order of Function Calls

Once a Tournament Manager has created a Referee, it may call `subscribe-as-game-observer`, `remove-game-observer`, and `run-game` at any point on the Referee.

Observers of the Referee will receive `FishGameEvent` updates for each game of Fish the Referee runs for which the observer subscribes via the `subscribe-as-game-observer` call, and has not been removed from the list of observers via the `remove-game-observer`, call prior to the Referee running the game via the `run-game` call.

A Referee may be used to run any number of games the Tournament Manager wishes. A Referee has no notion of concurrency. If a Tournament Manager wishes to run multiple games of Fish concurrently, it will create multiple Referees and follow this referee protocol for each one individually.Fi
