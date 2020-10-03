## Self-Evaluation Form for Milestone 1

### General 

We will run self-evaluations for each milestone this semester.  The
graders will evaluate them for accuracy and completeness.

Every self-evaluation will go out into your Enterprise GitHub repo
within a short time afrer the milestone deadline, and you will have 24
hours to answer the questions and push back a completed form.

This one is a practice run to make sure you get


### Specifics 


- does your analysis cover the following ideas:

  - the need for an explicit Interface specification between the (remote) AI 
    players and the game system?

This interface is provided in the Game Controller, and we note that "To the players of the game, it will provide endpoints to perform specific moves and to get the board state." By providing this Interface with endpoints to control interact with the game, we will allow remote players to play while also inserting a layer of indirection in order to minimize cheating and loopholes that could arise if the Game Model were visible.


  - the need for a referee sub-system for managing individual games

We consider this to be baked into the Board Model, as noted: "The game model manages the state of the Fish game....will act as the referee, implementing rule logic and preventing cheating." In the MVC scheme, the model is the ground truth for the logic of the system which allows for layers of indirection which prevent viewing or setting any information that the players shouldn't be able to access. If a player of the game tries to cheat by submitting an illegal move or playing out of turn, the model will simply not allow it. Additionally, there will be no way for a player to alter the board, their score, or other's scores, because the board model will be the source of truth for the state of the game.


  - the need for a tournament management sub-system for grouping
    players into games and dispatching to referee components

Yes, we included this in a separate Tournament MVC stack. Our thought process was that the concept of a tournament is entirely separate from the concept of a game; we should allow multiple games at the same time, at different tiers of the tournament bracket, and each game should have it's own model and controller providing the board/referee, and the interface through which to interact with that game.


- does your building plan identify concrete milestones with demo prototypes:

  - for running individual games

Our 3rd milestone, the Game Controller, includes this demo by noting that "After the game controller is complete, a real game with user interaction can be demonstrated." While we were not certain if all players would be AI or if there would be a mix of AI/Human players, by this milestone we should have 1. a completed board/referee system, 2. a view that will enable us to demo to a panel of non-technical stakeholders, and 3. a controller providing the interface endpoints for players to play the game, which are all 3 components we believed we would need to run a single Fish game.


  - for running complete tournaments on a single computer 

Yes, our final milestone would complete the Tournament MVC stack which would allow a real tournament to be played locally (and remotely as well). With a completed Tournament model and controller the game could be run, but we prioritized the GUI before the controller in order to demo a mocked tournament without actual games being run (just RNG to determine who the "winner" of the fake players was) at an earlier stage.


  - for running remote tournaments on a network

Unfortunately, we don't explicitly state that this is a demoable milestone we need to accomplish, but our system should still allow for it. While we misunderstood the way a player would interact with the game, we believe our system still accomplishes this goal by allowing interface endpoints to register for a tournament via the Tournament Controller, and interface endpoints to play a game via the Game Controller. We thought that users would upload their players to the system to be run locally, but there is no reason we couldn't accommodate a networked game by having players simply interact with our tournament and game interfaces.


- for the English of your memo, you may wish to check the following:

  - is each paragraph dedicated to a single topic? does it come with a
    thesis statement that specifies the topic?

Yes, we had dedicated paragraphs for each of our topics. We used subheadings to divide up our memos to address each topic. Some shorter paragraphs with subheadings did not have direct thesis statements, but our larger, explanatory parts of our memos did.  


  - do sentences make a point? do they run on?

Yes, our sentences made a point. Our goal was to be concise so there would be less ambiguity in our memos. Run on sentences and filler words can obscure important technical details and make a spec hard to reason about. 


  - do sentences connect via old words/new words so that readers keep
    reading?

Yes, in our systems introduction we introduced the idea of Model-View-Controller stacks (MVC) and introduces names for each of the corresponding parts needed for the game/tournament systems. These names were used across the rest of the systems and milestone memos. 


  - are all sentences complete? Are they missing verbs? Objects? Other
    essential words?

Yes, our sentences are complete and are not missing verbs/objects. As stated above, we wanted to fit as much technical information absolut our design into our systems memo as possible, so we limited filler words. 


  - did you make sure that the spelling is correct? ("It's" is *not* a
    possesive; it's short for "it is". "There" is different from
    "their", a word that is too popular for your generation.)

Yes, we checked our grammar as we were writing the memos and both did a final pass before submission. 


The ideal feedback are pointers to specific senetences in your memo.
For PDF, the paragraph/sentence number suffices. 

For **code repos**, we will expect GitHub line-specific links. 


