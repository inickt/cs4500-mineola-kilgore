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
  - We added documentation.
  - [Commit](https://github.ccs.neu.edu/CS4500-F20/kilgore/commit/9780176b9935693a4cfcf07473eebf9a4881f99a)