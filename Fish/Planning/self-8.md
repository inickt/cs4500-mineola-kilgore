## Self-Evaluation Form for Milestone 8

Indicate below where your TAs can find the following elements in your strategy and/or player-interface modules:

1. did you organize the main function/method for the manager around
the 3 parts of its specifications --- point to the main function

Yes: (1) inform starting (2) run the games (3) inform winners

https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/ff0324e325686bdd925760c583bbabbbab5b9c4f/Fish/Admin/manager.rkt#L40-L59

2. did you factor out a function/method for informing players about
the beginning and the end of the tournament? Does this function catch
players that fail to communicate? --- point to the respective pieces

Yes.

[Inform about the beginning](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/ff0324e325686bdd925760c583bbabbbab5b9c4f/Fish/Admin/manager.rkt#L78-L84)

[Inform about the end](https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/ff0324e325686bdd925760c583bbabbbab5b9c4f/Fish/Admin/manager.rkt#L86-L92)

Both functions return the `Result` struct which contains a set of kicked players, which we use to exclude players that fail to communicate.


3. did you factor out the main loop for running the (possibly 10s of
thousands of) games until the tournament is over? --- point to this
function.

Yes. https://github.ccs.neu.edu/CS4500-F20/kilgore/blob/ff0324e325686bdd925760c583bbabbbab5b9c4f/Fish/Admin/manager.rkt#L105-L134

**Please use GitHub perma-links to the range of lines in specific
file or a collection of files for each of the above bullet points.**


  WARNING: all perma-links must point to your commit "ff0324e325686bdd925760c583bbabbbab5b9c4f".
  Any bad links will be penalized.
  Here is an example link:
    <https://github.ccs.neu.edu/CS4500-F20/kilgore/tree/ff0324e325686bdd925760c583bbabbbab5b9c4f/Fish>

