# Tournament Manager Protocol
The protocol the Server Component will use to interact with a Tournament Manager is as follows:

## Functions
There is only one function that a Server Component may call on a Tournament manager.
- `run-tournamant`
  - Runs a Fish tournament with the given players (and their ages, as a positive number based on their registration) and a list of Tournament Observers. Players are implementations of the `player-interface`. The tournamaent will manage creating the refereee, configuring a bracket/system for playing out a tournament, reporting results to the observers, and making sure all games are completed. At the end of the tournament it returns a Ranking of all players that entered the tournament.

### Order of functions
Once a Server Component has created a Tournament Manager, it may call `run-tournament` any number of times as long as it provides at least two players.

Observers of the Tournament Manager will receive TournamentEvent updates after the completetion of each game in the tournament.

A Tournament Manager may be used to run any number of tournaments the Server Component wishes. A Tournament Manager has no notion of concurrency. If a Server Component wishes to run multiple tournaments of Fish concurrently, it will create multiple Tournament Managers and follow this tournament manager protocol for each one individually.

## Specification
The implementation for a Tournament Manager using the interface should abide by the following specifications:

### Tournament Structure
The tournament should be run in a number of rounds, configured by a parameter in the constructor of the Tournament Manager class. Each round consists of players being randomly subdivided into games of 2, 3, or 4, such that each player plays exactly one game per round. The Tournament Manager would preferably match players who have not played against each other previously. There Tournament Manager should have no preference for the number of players per game.

All players begin the tournament with zero points. After each round, a player would earn the following number of points, depending on the number of players in a game:

|       | 2 Player Game | 3 Player Game | 4 Player Game |
| ----- | ------------- | ------------- | ------------- |
| 1st | 1 | 1 | 1 |
| 2nd | 0 | 1/2 | 2/3 |
| 3rd | | 0 | 1/3 |
| 4th | | | 0 |

A player's score should be the sum of the points they have earned across all rounds. This is the score that should be used to produce Rankings and Standings. 
After each game, the Tournament Manager informs each observer of the game's Standing. At the end of the tournament, a list of Rankings will be returned.

### Referee Interactions
- how to use referee to run a game

If a player is kicked from a game by the referee, 

### Observsers
After each game in 
- how to call observers 

## Notes

