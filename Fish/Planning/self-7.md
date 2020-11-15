## Self-Evaluation Form for Milestone 7

Please respond to the following items with

1. the item in your `todo` file that addresses the points below.
    It is possible that you had "perfect" data definitions/interpretations
    (purpose statement, unit tests, etc) and/or responded to feedback in a 
    timely manner. In that case, explain why you didn't have to add this to
    your `todo` list.

2. a link to a git commit (or set of commits) and/or git diffs the resolve
   bugs/implement rewrites:

These questions are taken from the rubric and represent some of the most
critical elements of the project, though by no means all of them.

(No, not even your sw arch. delivers perfect code.)

### Board

- a data definition and an interpretation for the game _board_

  1. [Previously fixed before this week] "...the data definitions for state/board are vague"
  2. [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/5e1a29c4a87e1bd042a61c452fa8958f55a080dc) and [current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/board.rkt#L39-L73).

- a purpose statement for the "reachable tiles" functionality on the board representation

  1. We received no feedback on our reachable tiles, and think its functionality is clear
  2. [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/board.rkt#L140-L141)

- two unit tests for the "reachable tiles" functionality

  1. We had tests for reachable tiles from its implementation and received no feedback
  2. [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/board.rkt#L334-L354)

### Game States

- a data definition and an interpretation for the game _state_

  1. [Previously fixed before this week] We fixed some naming and data definitions for our game state:
     - "Inconsistent use of both State and GameState names instead"
     - "Unclear how the state maintains who is the current player, and the data definitions for state/board are vague"
  2. - [Commit 1](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/ec21879451f4a995ea0e1e13f951256517fbae05#diff-f03a4e8df557e1ea0e5e533ec074eea4)
     - [Commit 2](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/b7dbaebd545d639e35bee2be9b6cc00cfddfde40)
     - [Commit 3](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/5e1a29c4a87e1bd042a61c452fa8958f55a080dc)
     - [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/state.rkt#L48-L88)

- a purpose statement for the "take turn" functionality on states

  1. Our state used to be able to move any penguin by color and not maintain the current player. This was fixed in the above commits but we received no direct feedback on our "take turn" functionality"
  2. [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/state.rkt#L117-L131)

- two unit tests for the "take turn" functionality

  1. As mentioned above, we received no direct feedback on our "take turn" tests but over time as we reworked state we had updated some tests to take in to account things like the current player
  2. [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/state.rkt#L301-L320)

### Trees and Strategies

- a data definition including an interpretation for _tree_ that represent entire games

  1. [Previously fixed before this week] "Game tree is not actually a tree and contains the current player"
  2. - [Commit 1](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/6bcf17a91c55217ada306089400edaecc7bfe4c6)
     - [Commit 2](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/2a90f4b843a8f357f55221e52fb5af1443742a1a)
     - [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/game-tree.rkt#L29-L50)

- a purpose statement for the "maximin strategy" functionality on trees

  1. [Previously fixed before this week] "In `strategy.rkt` is no interpretation of output posn when choosing a placement"
  2. - [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/36840efd08c64afb568d39b9b472391d2e54b3e0)
     - [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Player/strategy.rkt#L40-L41)

- two unit tests for the "maximin" functionality

  1. We received no direct feedback on our "maximin" functionality
  2. [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Player/strategy.rkt#L161-L168)

### General Issues

Point to at least two of the following three points of remediation:

- the replacement of `null` for the representation of holes with an actual representation

  1. We never used `null` for our board representation, instead using 0 for holes.
  2. [Current state](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/c376d687837679c9ba0f54c5ebc01a495858daba/Fish/Common/tile.rkt#L53-L55)

- one name refactoring that replaces a misleading name with a self-explanatory name

  1. Previously fixed before this week] Mentioned above, we changed `GameState` to `State` since it had inconsistent use
  2. [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/ec21879451f4a995ea0e1e13f951256517fbae05#diff-f03a4e8df557e1ea0e5e533ec074eea4)

- a "debugging session" starting from a failed integration test:
  - the failed integration test
  - its translation into a unit test (or several unit tests)
  - its fix
  - bonus: deriving additional unit tests from the initial ones

  1. This week we fixed 11 broken integration tests in xstrategy. "The `tiebreaker` function in `strategy.rkt` incorrectly checks the 'to' positions before the 'from' positions"
  2. - Tests for broken functionality added [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/633e735e62c837f87384a2f09c64af931e58d22d).
     - Fixed by reordering the branches of the conditional [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/81bc09c7b9006a993fc60756d3144dd4ef408dd2).
     - Run xstrategy integration tests in our test suite [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/e47e35cc71c2ed3290886890b0987e0e4d3af3b1).

### Bonus

Explain your favorite "debt removal" action via a paragraph with
supporting evidence (i.e. citations to git commit links, todo, `bug.md`
and/or `reworked.md`).

Although not this week, the biggest/best debt removal happened when Nick and Jake had
completely reworked the state and game tree in one week to fix a bunch of issues brought
up in grading and code walks. Part of the reason it was great is it left us very little
to work on this week. We mostly did small cleanups or bug fixes introduced from tests
this week. It shows that a well maintained codebase and frequent small reworks is much
easier to maintain in the long run, and allows for time to be spent fixing smaller
issues. Over time those small changes can add up in making sure a codebase can be
accurate and well maintained.

Game tree changes:
- Made children a part of the game tree, added caching
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/6bcf17a91c55217ada306089400edaecc7bfe4c6)
- [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/2a90f4b843a8f357f55221e52fb5af1443742a1a)

State changes:
- [Commit 1](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/ac6b466085e184979f02f6fb19c0dd8a5e36906c)
- [Commit 2](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/edc88ac1886f32c8373c72d822c552c3b7bf6f80)
- [Commit 3](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/028ef15d290f8ac3efd1d12311feb090e317687f)
- [Commit 4](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/dafca5fdb109bde755296f8a13260f45dd23eed2)
- [Tests/cleanup](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/b688d7f21da19ec2c613405d0e4fab96858c8da8)
