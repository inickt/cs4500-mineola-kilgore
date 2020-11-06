# Tournament Manager Protocol
The protocol the Server Component will use to interact with a TournamentManager is as follows:

## Functions
There is only one function that a Server Component may call on a TournamentManager.
- `run-tournamant`
  - Runs a Fish tournament with the given players (and their ages, as a positive number based on their registration) and a list of TournamentObservers. Players are implementations of the `player-interface`. The tournamaent will manage creating the Referee, configuring a bracket/system for playing out a tournament, reporting results to the observers, and making sure all games are completed. At the end of the tournament it returns a Ranking of all players that entered the tournament.

### Order of functions
Once a Server Component has created a TournamentManager, it may call `run-tournament` any number of times as long as it provides at least two players.

Observers of the TournamentManager will receive TournamentEvent updates after the completetion of each game in the tournament.

A TournamentManager may be used to run any number of tournaments the Server Component wishes. A TournamentManager has no notion of concurrency. If a Server Component wishes to run multiple tournaments of Fish concurrently, it will create multiple TournamentManagers and follow this tournament manager protocol for each one individually.

## Specification
The implementation for a TournamentManager using the interface should abide by the following specifications:

### Tournament Structure
The tournament should be run in a number of rounds, configured by a parameter in the constructor of the TournamentManager class. Each round consists of players being randomly subdivided into games of 2, 3, or 4, such that each player plays exactly one game per round. The TournamentManager would preferably match players who have not played against each other previously. There TournamentManager should have no preference for the number of players per game.

All players begin the tournament with zero points. After each round, a player would earn the following number of points, depending on the number of players in a game:

|       | 2 Player Game | 3 Player Game | 4 Player Game |
| ----- | ------------- | ------------- | ------------- |
| 1st   | 1             | 1             | 1             |
| 2nd   | 0             | 1/2           | 2/3           |
| 3rd   |               | 0             | 1/3           |
| 4th   |               |               | 0             |

A player's score should be the sum of the points they have earned across all rounds. This is the score that should be used to produce Rankings and Standings. 
After each game, the TournamentManager informs each observer of the game's Standing. At the end of the tournament, a list of Rankings will be returned.

### Referee Interactions
At the start of each game, the Tournamanet Manager will call the `run-game` function provided by the Referee protocol to run a singular game in the tournament. The TournamentManager is repsonsible for running games concurrently, if it desires. 

If a player is kicked from a game by the Referee they earn no points for that game, but are eligible to continue playing in the tournament.

### Observsers
The TournamentManager should subscribe itself, or some componet, as a GameObserver to each Referee it creates. It should store the sequence of FishGameEvents in order for each game played. At the end of each game, it will compose a TournamentEvent from the sequence of FishGameEvents and the tournament Standing and then call the `observe` method on each observer.

## Notes
The following are external data definitions refrenced in this protocol:
- [TournamentManager](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/manager-interface.rkt#L26-L51)
- [Referee](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/referee-interface.rkt#L15-L51)
- [player-interface](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/manager-interface.rkt#L26-L51)
- [TournamentObserver](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/observer-interface.rkt#L87-L97)
- [GameObserver](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/observer-interface.rkt#L70-L78)
- [FishGameEvent](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/observer-interface.rkt#L22-L52)
- [TournamentEvent](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/observer-interface.rkt#L80-L85)
- [Ranking](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/manager-interface.rkt#L13-L24)
- [Standing](https://github.ccs.neu.edu/CS4500-F20/mineola/blob/899544641227f47841daa882728f71693b63bfa1/Fish/Admin/observer-interface.rkt#L54-L68)
