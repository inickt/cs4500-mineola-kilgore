# Reworked

`Board` representation leaks implementation details by not providing helpers to get the number of rows and columns

- We provided out the `board-rows` and `board-columns` helpers and used them in `strategy.rkt`.
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/33d3330aa472c1b3354246aa06c503dd2ae299c2)

When the game ends, we remove all players' penguins from the state, which is not required and obfuscates test cases.

- We got rid of the `finalize-state` function, which also had a inaccurate purpose statement.
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/951a5e03c24750becd5fd55ddbc326d5a3140c12)

Missing tests for in referee for misbehaving players

- We added more types of bad players and passed the to all the unit tests
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/6553c6d4c8066eedd3eb55ee4f4fbc52e80bfa29)

Missing documentation for how referee handles misbehaving players

- We added documentation describing exactly what cheating and failing are.
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/9780176b9935693a4cfcf07473eebf9a4881f99a)

Some exported functions in board are in the internal part of the file.

- We moved the functions up.
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/2161e711cfb2e85467c64bceded8ba3a247209cd)

## Previously Reworked Items

State does not store player information correctly (location of penguins, player score, current player turn)
and is missing functionality for seeing if players can move.

- Lots of commits spread apart for fixing player storage and interface for interacting with the state
- [Commit 1](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/ac6b466085e184979f02f6fb19c0dd8a5e36906c)
- [Commit 2](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/edc88ac1886f32c8373c72d822c552c3b7bf6f80)
- [Commit 3](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/028ef15d290f8ac3efd1d12311feb090e317687f)
- [Commit 4](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/dafca5fdb109bde755296f8a13260f45dd23eed2)
- [Tests/cleanup](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/b688d7f21da19ec2c613405d0e4fab96858c8da8)

Inconsistent use of both State and GameState names instead

- Rename everything to State, drop game state usage
- [Commit 1](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/ec21879451f4a995ea0e1e13f951256517fbae05#diff-f03a4e8df557e1ea0e5e533ec074eea4)
- [Commit 2](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/b7dbaebd545d639e35bee2be9b6cc00cfddfde40)

Game tree is not actually a tree and contains the current player

- Made children a part of the game tree, added caching
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/6bcf17a91c55217ada306089400edaecc7bfe4c6)
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/2a90f4b843a8f357f55221e52fb5af1443742a1a)

Unclear how the state maintains who is the current player, and the data definitions for state/board are vague

- Updated data definitions
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/5e1a29c4a87e1bd042a61c452fa8958f55a080dc)

`player-interface.rkt` needs more documentation (information contained in `player-protocol.md`)

- Added more documentation
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/1ba5417c7bdbd725624095ca72f319a7bc2fff7d)

In `strategy.rkt` is no interpretation of output posn when choosing a placement

- Added more documentation
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/36840efd08c64afb568d39b9b472391d2e54b3e0)
