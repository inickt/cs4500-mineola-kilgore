# Outstanding Items to Fix

- [x] Fix 11 broken integration tests from Milestone 6 caused by a bad tiebreaker
- [x] `Board` representation leaks implementation details by not providing helpers to get the number of rows and columns
- [x] `finalize-state` removes all players' penguins from a state, has incorrect purpose statements, and is not functionally required
- [x] Add cheating player tests in referee for players trying to place/move illegal options
- [x] Document how referee handles misbehaving players
- [ ] The strategy component is too complicated and applies the tiebreaker at every step in the algorithm
- [x] Hexagon position movers are marked as internal but are actually public

## Previous Addressed Feedback Items

- [x] Fix failing integration tests from Milestones 3, 4, and 5
- [x] State does not store players correctly (location of penguins, player score, current player turn)
- [x] Missing functionality in state that checks if no move is possible (and unit tests for this)
- [x] Use both State and GameState names
- [x] Players in both State and Game
- [x] Game tree is not actually a tree
- [x] Unclear how the state maintains who is the current player, and the data definitions for state are vague
- [x] `player-interface.rkt` needs more documentation (information contained in `player-protocol.md`)
- [x] `strategy.rkt` has no interpretation of output posn when choosing a placement
- [x] For choosing turn action, the purpose statement doesn't specify what happens if the current player cannot make a move
- [x] Inconsistencies between board position data definitions for rows/columns
