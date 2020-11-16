
We will use the remote proxy pattern to translate communication over the network into method calls and vice versa. On the Admin side, we will develop a `remote player` that implements the existing `player-interface`. When methods are called on the `remote player`, it will serialize the arguments and send the over the network to the player. On the Client side, we will create a Racket library that wraps the communication and calls the appropriate methods on the `player-interface` implemented by the user. Note that users can also register remote players implemented in any language, as long as they follow our communication protocol.

## Timing of the protocol

1. The signup component creates a proxy player when players signup.
2. When a tournament begins, the tournament manager creates a referee and passes it the proxy players.
3. The referee sends the `initialize` to each player.
4. The referee sends `get-placement` and `get-move` as the game progresses.
5. If players misbehave, the referee sends `terminate`.
6. When the game ends, the referee sends `finalize`.
7. As the tournament progresses, `initialize` will be sent again for each new game.
8. When the tournament ends, `finalize-tournament` will be sent with who won the game.

