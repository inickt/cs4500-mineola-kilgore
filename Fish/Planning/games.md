**Date:** Oct. 15, 2020  
**To:** CS4500 Staff  
**From:** Jake Hansen and Nick Thompson  
**Subject:** Fish Game State Design  

## Data Representation
A `Game` will be represented by the following data definition:
```racket
(define-struct game [current players previous])
;; A Game is one of:
;; - state?
;; - (make-game State [Listof Player] Game)
;; which represents either the initial state or a make-game in which the current state
;; is the result of a single legal move (as determined by the RuleChecker component)
;; from the previous Game
;; The players field is an ordered list of Players, where the list is sorted by the turn order
;; such that player who's move it is is the 0th element, the next player is the 1st element, etc.

```

For reference, a `State` contains the board, penguins, and player order and is defined by the `GameState` definition [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/d571d121112cb572348bca4ce207a4b236783f20/Fish/Common/state.rkt#L25-L34).

A `Player` will be represented by the following data definition:
```racket
(define-struct player [score age pengin])
;; A Player is a (make-player Nat Nat Penguin) where:
;; - score is the player's score, starting from 0 and increasing by 1 for each fish their penguins collect.
;; - age is the player's age in years.
;; - penguin is the player's game token color, represented as a Penguin.
```

For reference, a `Penguin` is the color of a player's penguin tokens in the game, as defined [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/dc8e3a9aaee490b05e3f893d9809ed925781f6bd/Fish/Common/penguin.rkt#L21).

A tree representing all possible outcomes of a `Game` can be created by, starting with the initial `Game`, generating all legal moves and recurring on these `Game`s. Nodes of this tree are terminal `Game`s for which there exist no legal moves. In this way, a player can plan ahead by iteratively querying the Rulebook Interface with a proposed move for a hypothetical `Game` state.

The Player ordering is determined by the order of the `players` field of a `Game`. A player may determine that they are the current player able to make a move by determining that they appear in the 0th index of the `players` list. Upon performing a move, the new `Game` will rotate this list such that the player who is able to perform a move in the next `Game` state is the 0th index of the list, and the player who just performed a move is the last element of the list. If a player is kicked from the game for cheating, the next `Game` state will not include that player in the `players` list.

Players will only be able to modify a `Game` through the Referee. They will have no ability to modify the `Game` directly, to prevent cheating. However, both players and the Referee will be able to consult the Rulebook Interface to determine the resultant `Game` from any move performed on any hypothetical `Game` state. If the resultant game state has removed the player and not performed the move, they will know that it violates the rules of Fish.

### The Rulebook Interface
This interface will be provided to the Referee component only. Players wishing to modify a Game of Fish must do so through the Referee component's external interface.

**perform-move : Player Posn Posn Game -> Game**  
Firstly, consults the Rulebook Component to determine whether the desired move is valid. If the move is illegal, removes the Player from the Game.
Next, performs the move, returning the Game resulting from the move being applied to the previous Game.

**can-perform-move? : Player Posn Posn Game -> Boolean**  
Returns whether or not the given move is legal. When calling `perform-move`, `can-perform-move` may be called first to ensure the move is legal.

**get-turn-order : Game -> \[List of Player\]**  
Gets an ordered list of players, where the first player is the player who's turn it currently is, and each subsequent player is the player who will act immediately after the player before them, pending the availability of valid moves for that player.

**can-move : Posn Game -> Boolean**  
Determines whether the `Penguin` at the given position has any available legal moves.

**valid-moves : Posn Game -> \[Set of Posn\]**  
Determines the set of valid moves from the `Penguin` at the given position.

**get-penguins-for-player : Player Game -> \[Set of Posn\]**  
Gets the set of positions for which the specified player has `Penguins` on the `Board`.

**get-board : Game -> \[List of \[List of Natural\]\]**  
Gets the current `Board`, providing the Fish counts at each position and where holes are.
The output list is a List of Rows, meaning it is indexed by \[Row, Column\].
Note: Does not encode the locations of any players' `Penguin`s.
