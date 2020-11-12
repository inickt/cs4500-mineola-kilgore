# Reworked
`Board` representation leaks implementation details by not providing helpers to get the number of rows and columns
   - We provided out the `board-rows` and `board-columns` helpers and used them in `strategy.rkt`.
   - [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/33d3330aa472c1b3354246aa06c503dd2ae299c2)

When the game ends, we remove all players' penguins from the state, which is not required and obfuscates test cases.
  - We got rid of the `finalize-state` function, which also had a inaccurate purpose statement.
  - [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/951a5e03c24750becd5fd55ddbc326d5a3140c12)