## Self-Evaluation Form for Milestone 5

Under each of the following elements below, indicate below where your
TAs can find:

- the data definition, including interpretation, of penguin placements for setups 

We did not need to create any new data definitions for the placement of penguins, because by default Racket provides the `posn` struct. All (x, y) or (row, col) coordinate pairs, such as those used to represent the desired placement for a penguin, are encoded as posns. We describe the ways a player's penguins must meet the board's coordinate system specification here:  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6ce07d4cd505b92442d1e4941a5465d35870fbae/Fish/Common/state.rkt#L63-L74  
And under the bolded section below you can find our description of the `Board`'s coordinate system.

- the data definition, including interpretation, of penguin movements for turns

https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6ce07d4cd505b92442d1e4941a5465d35870fbae/Fish/Common/state.rkt#L76-L86


**Both of the above refer to the coordinate system here:**  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6ce07d4cd505b92442d1e4941a5465d35870fbae/Fish/Common/board.rkt#L43-L68


- the unit tests for the penguin placement strategy 

https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6ce07d4cd505b92442d1e4941a5465d35870fbae/Fish/Player/strategy.rkt#L123-L144

- the unit tests for the penguin movement strategy; 
  given that the exploration depth is a parameter `N`, there should be at least two unit tests for different depths 
  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/6ce07d4cd505b92442d1e4941a5465d35870fbae/Fish/Player/strategy.rkt#L146-L153
  
- any game-tree functionality you had to add to create the `xtest` test harness:
  - where the functionality is defined in `game-tree.PP`
  - where the functionality is used in `xtree`
  - you may wish to submit a `git-diff` for `game-tree` and any auxiliary modules 
  
We had to refactor `game-tree.rtk` to move the current turn to `state.rkt` and to make our data representation *actually* a tree. No functionality was added specifically for `xtree`.

**Please use GitHub perma-links to the range of lines in specific
file or a collection of files for each of the above bullet points.**

  WARNING: all perma-links must point to your commit "6ce07d4cd505b92442d1e4941a5465d35870fbae".
  Any bad links will result in a zero score for this self-evaluation.
  Here is an example link:
    <https://github.ccs.neu.edu/CS4500-F20/mineola/tree/6ce07d4cd505b92442d1e4941a5465d35870fbae/Fish>

