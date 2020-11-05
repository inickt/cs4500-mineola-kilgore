# Player Protocol  
The protocol that the Referee will use to interact with a Player is as follows:

#### Functions  
There are 6 functions that the Referee may call on a Player.
- `initialize`
  - Informs the Player that a game with the given board and number of Players will begin, and that the Player's penguin avatars will have the given color.
- `get-placement`
  - Informs the player of the current `State`. The Player returns it's next desired placement as a `(make-posn column row)` for a penguin.
- `get-movement`
  - Informs the player of the current `Game`. The Player returns it's next `Move`.
- `finalize`
  - Informs the player of the final `EndGame`, which is guaranteed to be terminal (no more moves can be made).
- `terminate`
  - Informs the player that it has been kicked from the game.

#### Order of Function Calls  
The order of function calls will be dependent on the phase of the game. The following phases are in order:

##### Initialization phase  
`initialize` will be called once on each Player as a game of Fish is beginning.

##### Placement phase  
`get-placement` will be called (6 - N) times in total for a single Player, where N is the number of Players in the game. It will be called according to the play order† in a round-robin fashion until each Player in the game has placed all of its penguins. It will immediately cease to be called on any player who is kicked.

##### Play phase
`get-move` will be called according to the play order† in a round-robin fashion until an `EndGame` has been reached. It will not be called on any kicked player from the moment it is kicked onwards.

##### Finalization phase
`finalize` will be called once on each Player, providing the `EndGame`.

##### Termination
During the Placement phase and beyond, a Player may perform a move which violate the rules of Fish. The Referee will call `terminate` once on this player, and then remove this Player's penguins from the `Game`.

#### Notes  
†Play order: As per the [rules](https://www.ccs.neu.edu/home/matthias/4500-f20/fish.html) the Players take turns in ascending order of their age. If a Player is kicked, their turn is skipped each round.  

`State` is defined [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/0638250021bf92a4a20a9fb254cb681de8ef4a34/Fish/Common/state.rkt#L47-L54).  
`GameTree`, `Game`, and `EndGame` are defined [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/0638250021bf92a4a20a9fb254cb681de8ef4a34/Fish/Common/game-tree.rkt#L16-L40).  
`Move` is defined [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/0638250021bf92a4a20a9fb254cb681de8ef4a34/Fish/Common/state.rkt#L64-L66).  
`PenguinColor` is defined [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/0638250021bf92a4a20a9fb254cb681de8ef4a34/Fish/Common/penguin-color.rkt#L22-L35).

- The Referee will only send well formed, valid data to a Player as arguments to each function specified in the Player Interface.
- During the initialization phase, a set of `PenguinColor`s will be determined for the game. Each Player will be assigned a `PenguinColor` when `initialize` is called on that Player.
- If a Player provides a return value to `get-placement` or `get-move`, the Referee may kick this Player from the game. Their penguins will be removed from the `Game`, and their turn will be skipped each round.  
- `finalize` will only be called with an `EndGame`.
