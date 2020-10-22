![ProtocolDiagram](./PlayerProtocolDiagram.png)

## Player Protocol  
The protocol that the Referee will use to interact with a Player is as follows:

#### Functions  
There are 6 functions that the Referee may call on a Player.
- `initialize`
  - Informs the player that a game with the given board and number of players will begin, and that the player's penguin avatars will have the given color. The player returns it's age in years.
- `get-placement`
  - Informs the player of the current `State`. The Player returns it's next desired placement for a penguin.
- `get-movement`
  - Informs the player of the current `Game`. The Player returns it's next `Move`.
- `finalize`
  - Informs the player of the final `Game`, which is guaranteed to be terminal (no more moves can be made).
- `listen`
  - Informs the player of the new `Game` any time any Player performs an action that produces a new `Game`.
- `terminate`
  - Informs the player that it has been kicked from the game, with a provided reason which the player may desire to log.

#### Order of Function Calls  
The order of function calls will be dependent on the phase of the game. The following phases are in order:

##### Initialization phase  
`initialize` will be called once on each player as a game of Fish is beginning.

##### Placement phase  
`get-placement` will be called (6 - N) times in total for a single player, where N is the number of players in the game. It will be called according to the play order† in a round-robin fashion until each Player in the game has placed all of its penguins.

##### Play phase
`get-move` will be called according to the play order† in a round-robin fashion until the `Game` a terminal `Game` has been reached.

##### Finalization phase
`finalize` will be called once on each player, providing the terminal `Game`.

##### Termination
During the Placement phase and beyond, a player may perform a move which violate the rules of Fish. The Referee will call `terminate` once on this player, providing a string reason for which the player was kicked, and then remove this player from the `Game`.

##### Listening
Players may use algorithms which utilize all available time searching for optimal moves given the currently known `Game`. To accommodate this, each time a Player action causes the current `Game` to progress, `listen` will be called once for each player providing the newest `Game`. Players may safely perform a no-op return on this function.

#### Notes  
Define play order
Define `State`
Define `Game`
Define `Move`
Talk about illegal data inputs to Player functions  
Talk about how on intitialization the state picks a subset of colors, and as ages become known each player gets assigned a color  
Cannot call finalize with a Game that is not a leaf node  
Protocol violation warning  
Link to `Move` definition from programming task  
Talk about `listen` method  

#### Protocol

What functions do the players provide?  
What order will the referee call the functions in?  

