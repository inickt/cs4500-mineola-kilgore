# Bugs Fixed
The `tiebreaker` function in `strategy.rkt` incorrectly checks the 'to' positions before the 'from' positions
 - Tests for broken functionality added [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/633e735e62c837f87384a2f09c64af931e58d22d).
 - Fixed by reordering the branches of the conditional [here](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/81bc09c7b9006a993fc60756d3144dd4ef408dd2).
