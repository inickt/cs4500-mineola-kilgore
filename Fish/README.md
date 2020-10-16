# Fish
This project is to develop a game and tournament system for the board game Fish. Users will register themselves or their AI entrants to the competition. Once players have registered, games will begin.

Each game of Fish consists of 2-4 players placing 2-6 (dependant on the number of players) penguins onto a grid of hexagonal tiles. Each tile contains a certain number of fish, or may be a hole. Once all penguins are placed, the next phase of the game begins. Players may move their penguins in straight lines, but not over holes. When a penguin leaves a tile, it's player gains the number of fish that were on the tile, and the tile becomes a hole. The game ends when no penguins are able to move, at which point the tiles they are on are removed and their players gain those fish as points.

The Fish Game system will run individual games of Fish, determining a winner (or winners) by the player(s) with the highest score. Winners advance in the tournament bracket.

## Directory Structure
```
Fish/
├── Common/
│   ├── board.rkt
│   ├── penguin.rkt
│   ├── state.rkt
│   └── tile.rkt
├── Planning/
│   ├── game-state.md
│   ├── games.md
│   ├── milestones.pdf
│   ├── self-1.md
│   ├── self-2.md
│   └── system.pdf
└── README.md
```

### Common
Contains all information for building a spec for a Fish tournament and game systems.

##### board.rkt
Contains the data and function definitions describing a Fish board.
Provides a predicate for a Board, and functions to:
 1. Create a board with specified width, height, holes, and some minimum number of 1-fish tiles.
 2. Create a board with a given width and height with no holes and all tiles having the same fish count.
 3. Draw a board.
 4. Remove a tile from a board, creating a hole.
 5. Determine the legal moves from a given tile.
 
##### state.rkt
Contains the data and function definitions representing a state of a Fish game.
Provides functionality to:
 1. Create a game with a specified number of players.
 2. Place an avatar at a specific location on a Board.
 3. Move an avatar from one location to another on a Board.
 4. Determine a list of valid moves for a specific Penguin.
 5. Render the State.

##### penguin.rkt
Contains the data and function definitions describing a player's penguin color in a game of fish.
Provides an enumeration of Penguins, a function to draw a Penguin avatar, and a function to map a Penguin to the visual color used to represent penguins of that color.

##### tile.rkt
Contains the data and function definitions describing a tile.
Provides predicates for Tile and Hole, and a function to draw a tile.

### Planning
Contains all files dictating the common ontology for the Fish game system.

##### game-state.md
A memo release describing the components we believe are needed to complete the Fish game system's data definitions. Additionally, this file describes the external interface we would like to provide, through which players may interact with a game of Fish.

##### games.md
A memo release describing the data reperesentation and interface specifications we would like to use to represent an entire game of Fish. The data representation and interface are designed to be used by either a referee or player for legality checking moves and potentially planning ahead.

##### milestones.pdf
A memo release stating the intended milestones for the Fish game and tournament systems, including demoable intermediate steps.

##### self-1.md
A self reflective document describing our thoughts on systems.pdf and milestones.pdf in hindsight.

##### self-2.md
A self reflective document describing our thoughts on tile.rkt and board.rkt in hindsight.

##### systems.pdf
A memo release for planning the systems that the complete Fish game and tournament systems would require.

## Testing

Testing is handled by `raco`, Racket's command line tools. All tests can be run by executing
```
raco test .
```
in this directory. You can also run tests on a certain file or subfolder. For example,
```
raco test Common
```
would run all tests included in the Common directory.

We strive to maintain 100% code coverage in our tests. This can be verified by installing the `cover` package using
```
racko pkg install cover
```
It can be used similar to `raco test`, i.e.
```
raco cover .
```
would generage a `coverage/` folder in the current directory with `index.html` containing the coverage results.

