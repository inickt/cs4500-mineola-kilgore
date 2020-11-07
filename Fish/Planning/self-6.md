## Self-Evaluation Form for Milestone 6

Indicate below where your TAs can find the following elements in your strategy and/or player-interface modules:

The implementation of the "steady state" phase of a board game
typically calls for several different pieces: playing a *complete
game*, the *start up* phase, playing one *round* of the game, playing a *turn*, 
each with different demands. The design recipe from the prerequisite courses call
for at least three pieces of functionality implemented as separate
functions or methods:

- the functionality for "place all penguins"  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L100-L117

- a unit test for the "place all penguins" funtionality  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L265-L304

- the "loop till final game state" function  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L147-L164

- this function must initialize the game tree for the players that survived the start-up phase  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L52
  - Our `create-game` function will set up the game tree to make sure the current player has available moves (or create and end game when no players can move)

- a unit test for the "loop till final game state"  function  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L342-L376

- the "one-round loop" function  

- a unit test for the "one-round loop" function  

- the "one-turn" per player function  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L166-L176

- a unit test for the "one-turn per player" function with a well-behaved player  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L377-L382

- a unit test for the "one-turn" function with a cheating player  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L380

- a unit test for the "one-turn" function with an failing player  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L380
  - We also abstracted out our timeout/error checking which is tested [here](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L399-L402)

- for documenting which abnormal conditions the referee addresses  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee-interface.rkt#L34-L35

- the place where the referee re-initializes the game tree when a player is kicked out for cheating and/or failing  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish/Admin/referee.rkt#L161-L163


**Please use GitHub perma-links to the range of lines in specific
file or a collection of files for each of the above bullet points.**

  WARNING: all perma-links must point to your commit "6113d5162877ed8283c64a154a9fbd4745ad2225".
  Any bad links will be penalized.
  Here is an example link:
    <https://github.ccs.neu.edu/CS4500-F20/mineola/tree/6113d5162877ed8283c64a154a9fbd4745ad2225/Fish>

