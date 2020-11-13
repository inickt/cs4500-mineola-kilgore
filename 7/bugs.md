# Bugs Fixed

The `tiebreaker` function in `strategy.rkt` incorrectly checks the 'to' positions before the 'from' positions

- Tests for broken functionality added [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/633e735e62c837f87384a2f09c64af931e58d22d).
- Fixed by reordering the branches of the conditional [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/81bc09c7b9006a993fc60756d3144dd4ef408dd2).
- Run xstrategy integration tests in our test suite [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/e47e35cc71c2ed3290886890b0987e0e4d3af3b1).

## Previously Addressed Bugs

Fix failing integration tests from Milestones 3, 4, and 5

- Run xtree integration tests in our test suite [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/b62bdc503aae0578fcff99f3786457e025543bd0).
- Fix tiebreaker from failed integration tests [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/c920c650bec8d24d3bcdf0bcf3cc5b79ae764168).
- Run xboard and xstate integration tests in our test suite [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/5f2c8766bf90ab6822c16c57b5e01a43012825b8).
  - Includes fix in `xstate.rtk` lines 19-24 for outputting `False` on bad input data
