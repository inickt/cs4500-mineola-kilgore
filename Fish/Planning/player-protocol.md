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

#### Notes

Talk about illegal data inputs to Player functions
Talk about how on intitialization the state picks a subset of colors, and as ages become known each player gets assigned a color
Cannot call finalize with a Game that is not a leaf node
Protocol violation warning
Link to `Move` definition from programming task

#### Protocol

What functions do the players provide?
What order will the referee call the functions in?

