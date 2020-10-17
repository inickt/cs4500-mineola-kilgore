## Self-Evaluation Form for Milestone 3

Under each of the following elements below, indicate below where your
TAs can find:

- the data description of states, including an interpretation:  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/7f3f678fd9e12049f6df4281aa8779b06220b493/Fish/Common/state.rkt#L25-L34

- a signature/purpose statement of functionality that creates states:  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/7f3f678fd9e12049f6df4281aa8779b06220b493/Fish/Common/state.rkt#L39-L41

- unit tests for functionality of taking a turn:  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/7f3f678fd9e12049f6df4281aa8779b06220b493/Fish/Common/state.rkt#L211-L243

- unit tests for functionality of placing an avatar:  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/7f3f678fd9e12049f6df4281aa8779b06220b493/Fish/Common/state.rkt#L190-L210

- unit tests for functionality of final-state test:  
https://github.ccs.neu.edu/CS4500-F20/mineola/blob/7f3f678fd9e12049f6df4281aa8779b06220b493/Fish/Common/state.rkt#L244-L267  

We misread the assignment task, *"determine whether **any** player can move an avatar"* as *"determine whether **a** player can move an avatar"*. As a result, we don't have a test for this functionality exactly. Our `can-move?` function could be used to get this same information by using an `ormap` over all players:
```racket
;; Given a state?, state
(ormap (λ (player) (can-move? player state)) (state-players state))
```
We will fix/implement this shortly.

## Partnership Eval 

Select ONE of the following choices by deleting the other two options.

A) My partner and I contributed equally to this assignment. 

We have worked really well together!
