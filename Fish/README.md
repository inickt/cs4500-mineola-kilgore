# Fish
This project is to develop a game and tournament system for the board game Fish. Users will register themselves or their AI entrants to the competition. Once players have registered, games will begin.

Each game of Fish consists of 2-4 players placing 2-6 (dependant on the number of players) penguins onto a grid of hexagonal tiles. Each tile contains a certain number of fish, or may be a hole. Once all penguins are placed, the next phase of the game begins. Players may move their penguins in straight lines, but not over holes. When a penguin leaves a tile, it's player gains the number of fish that were on the tile, and the tile becomes a hole. The game ends when no penguins are able to move, at which point the tiles they are on are removed and their players gain those fish as points.

The Fish Game system will run individual games of Fish, determining a winner (or winners) by the player(s) with the highest score. Winners advance in the tournament bracket.

## Directory Structure
```
Fish
├── Common
│   ├── board.rkt
│   ├── tile.rkt
├── Planning
│   ├── game-state.md
│   ├── milestones.pdf
│   ├── self-1.md
│   └── system.pdf
└── README.md
```

### Planning
Contains all information for building a spec for a Fish tournament and game systems.

###### board.rkt
Contains the data and function definitions describing a Fish board.
Provides a predicate for a Board, and functions to:
 1. Create a board with specified width, height, holes, and some minimum number of 1-fish tiles.
 2. Create a board with a given width and height with no holes and all tiles having the same fish count.
 3. Draw a board.
 4. Remove a tile from a board, creating a hole.
 5. Determine the legal moves from a given tile.

###### tile.rkt
Contains the data and function definitions describing a tile.
Provides predicates for Tile and Hole, and a function to draw a tile.

### Common
Contains all files dictating the common ontology for the Fish game system.

###### systems.pdf
A memo release for planning the systems that the complete Fish game and tournament systems would require.

###### milestones.pdf
A memo release stating the intended milestones for the Fish game and tournament systems, including demoable intermediate steps.

###### self-1.md
A self reflective document describing our thoughts on systems.pdf and milestones.pdf in hindsight.

###### game-state.md
A memo release describing the components we believe are needed to complete the Fish game system's data definitions. Additionally, this file describes the external interface we would like to provide, through which players may interact with a game of Fish.

## Testing

Testing is handled by `raco`, Racket's command line tools. All tests can be run by running
```
raco test .
```
in this directory. You can also run tests on a certain file or subfolder. For example,
```
raco test Common
```
would run all tests included in the Common directory.

