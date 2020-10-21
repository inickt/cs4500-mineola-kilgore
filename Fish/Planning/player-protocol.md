```
Design Task The player components must communicate with the referee.
This communication involves both function/method calls and orderings of those,
i.e., a protocol. Since outsiders will program to this interface, it must be spelled
out precisely and in detail.

Write two documents: (1) the API for a player component in your chosen language and
(2) the protocol for this API. The first document (player-interface.PP) should be a
module in your language enriched with the usual descriptions (interpretations, purpose
statements). The second document (player-protocol.md) may use the usual mix of English,
terms from your language, and UML sequence diagrams (if desired).
```

#### Protocol

What functions do the players call?
What order do the players call the functions in?

**Functions a player may wish to use:**
- Who are the players of the game (and their scores/colors/order of play)?
- What players have been kicked from the game?
- Have I been kicked from the game?
- Who's turn is it? (synonym for Is it my turn?)
- What is the turn order?
- What moves can I make from a given game state?
- What moves can I make from a given game state using a certain penguin?
- Is the game over?
- Is a given move valid? (Will I be kicked for performing a given move?)
- Perform a move from the TO posn to the FROM posn

Potentially include:
- Can I place a penguin at the given posn?
- Place a penguin at the given posn
