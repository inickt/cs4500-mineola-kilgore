# Outstanding Items to Fix
- [x] Fix 11 broken integration tests from Milestone 6 caused by a bad tiebreaker
- [ ] `Board` representation leaks implementation details by not providing helpers to get the number of rows and columns
- [ ] `finalize-state` removes all players' penguins from a state, has incorrect purpose statements, and is not functionally required
- [ ] Add cheating player tests in referee for players trying to place/move illegal options
- [ ] Document how referee handles misbehaving players
- [ ] The strategy component is too complicated and applies the tiebreaker at every step in the algorithm
- [ ] Hexagon position movers are marked as internal but are actually public
