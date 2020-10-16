**Date:** Oct. 15, 2020  
**To:** CS4500 Staff  
**From:** Jake Hansen and Nick Thompson  
**Subject:** Fish Game State Design  

## Data Representation
A `Game` will be represented by the following data definition:
```racket
(define-struct game [current previous])
;; A Game is one of:
;; - state?
;; - (make-game state? Game)
;; which represents either the initial state or a make-game in which the current state
;; is the result of a single legal move (as determined by the RuleChecker component)
;; from the previous Game
```

For reference, a `state?` contains the board, penguins, and player order and is defined by the `GameState` definition [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/d571d121112cb572348bca4ce207a4b236783f20/Fish/Common/state.rkt#L25-L34).

### Rule Checker

The Rule Checker is the interface 
collection of functions

* set of functions that let you ask hypothetical functions
* set of functions that let you modify the game



## External Interface
The Game will provide two API interfaces externally for users to interact with:
- The Game interface, which provides functions to interact with a Fish Game.
- The Rulebook interface, which provides functions to ask about the legality of any move.

The Game interface will provide the following functions:
- 
```
all-possible-children : Game RuleChecker -> (listof Game) <- all of these games would have prev set to the input game
```

## Player and Referee
- who's turn
- get turn order
- can move
- valid moves
- board representation/values at tiles

## Referee
- remove player? remove penguin? both? same thing?
- move player






