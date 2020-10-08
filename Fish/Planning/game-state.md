**Date:** Oct. 8, 2020  
**To:** CS4500 Staff  
**From:** Jake Hansen and Nick Thompson  
**Subject:** Fish Game State Design  

# Data Representation
The data used to represent a full Fish game will be a structure called a FishGame, containing three major components, each a module with its own sub-components. Those three components are the Board, the Players, and the Rules.

## The FishGame
A FishGame will be a structure representing a single game of Fish as a state machine. Any request for information about the game state can be delegated to the Board subsystem; any request for information about the players can be delegated to the Players subsystem; lastly, any request about the validity of moves can be delegated to the Rules subsystem. Performing updates to the game state will result in calls and updates to any combination of the subsystems. Any event triggered by the controller will cause calls to the event handlers in the respective subsystems, and those subsystems will return their new state for the FishGame to manage.

## The Board Subsystem
The game board will be managed by the board, which we have implemented this week. It implements functionality to create game boards as a 2-dimensional vector of Tiles. The board provides functionality to initialize the board, manipulate the tiles of the game, and draw tiles and the full board.

## The Players Subsystem
The players of a FishGame will be stored in a structure of two lists. The first list contains player structures who are currently in the game. Each player struct will contain the player’s age, place in the turn ordering, score, and the locations of their currently placed penguins. The second list contained within the player subsystem will contain players who have been kicked from the game by the referee. This separation will ensure that no kicked player is ever mistakenly allowed to play.

## The Rules Subsystem
This subsystem will contain a minimal structure consisting of the original parameters of the game, which will act like constants as soon as the game begins. In addition, it will contain a set of functions which check the legality of action the controller attempts to perform on behalf of a user, and potentially trigger actions resulting from illegal moves such as kicking a player from the game if they attempt to cheat.

# Interface
The external interface to our game state will be designed to abstract away the game internals as much as possible, and only provide information that is not abusable. All return values will be as JSON. The provided functions will include, at a minimum:

**GetGameState : -> Object**  
Returns the entire game state, encompassing the board, current status, current player turn (if applicable), and current scores.

**GetGameBoard : -> Object**  
Returns the current game state containing the board and the locations of each player’s penguins.

**GetPlayerTurn : -> Natural**  
Returns the ID of the player whose turn it is.

**GetPlayers : -> Dictionary**  
Returns a map of player ID to JSON object containing that player’s age, current score, and turn ordering.

**GetGameStatus : -> String**  
Informs the requester whether the game hasn’t begun yet, is in the placement phase, is in the play phase, or has been completed.

**GetValidMoves : Natural Natural -> List**  
For the given (x, y), returns a list of JSON objects indicating all positions of valid moves from that tile. Note that for strategy purposes, any player can access this info regardless of whether there is a penguin, or who’s penguin is on that tile.

**IsValidPlace : Natural Natural -> Boolean**  
Determines whether placing the penguin at the given tile and if 

**IsValidMove : Natural Natural Natural Natural -> Boolean**  
Determines if the move from (x1, y1) to (x2, y2) is legal for that player.

**PlacePenguin : Natural Natural -> Object**  
Places a penguin at the given (x, y) location if it is that player’s turn and the location is valid. This function may only be called during the placement phase. Returns the new game board.

**MovePenguin : Natural, Natural, Natural, Natural -> JSON object**  
Moves a penguin from (x1, y1) to (x2, y2) if it is that player’s turn, they have a penguin at (x1, y1), and there is a path from (x1, y1) to (x2, y2). This function may only be called during the play phase. Returns the new game board.

**SubscribeAsListener : -> Object**  
Subscribes the caller to game event updates, including: when the game enters the placement phase, enters the play phase, ends (and what the final score is), when a new player’s turn begins, or when the referee ejects a player. Returns a socket for the subscriber to connect to.
