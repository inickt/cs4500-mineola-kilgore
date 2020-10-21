```
Design Task The player components must communicate with the referee. This communication involves both function/method calls and orderings of those, i.e., a protocol. Since outsiders will program to this interface, it must be spelled out precisely and in detail.

Write two documents: (1) the API for a player component in your chosen language and (2) the protocol for this API. The first document (player-interface.PP) should be a module in your language enriched with the usual descriptions (interpretations, purpose statements). The second document (player-protocol.md) may use the usual mix of English, terms from your language, and UML sequence diagrams (if desired).
```

#### Protocol

Hypotheticals:
- Who are the players of the game (and their scores/colors)?
- Who's turn is it? What is the turn order?
- What moves can I make from a given game state?
- 

Performs:
- Perform a move from the TO posn to the FROM posn

Data:
- the current Game needs to be stored
