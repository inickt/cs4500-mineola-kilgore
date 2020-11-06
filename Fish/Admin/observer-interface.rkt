#lang racket/base

(require racket/class
         racket/contract
         "../Common/board.rkt"
         "../Common/player-interface.rkt")

(provide start-event
         place-event
         move-event
         kick-event
         end-event
         fish-game-event?
         game-observer-interface
         game-observer?

         tournament-event?
         standing?
         tournament-observer-interface
         tournament-observer?)

(define-struct start-event [board player-colors])
(define-struct place-event [state position color])
(define-struct move-event [game move color])
(define-struct kick-event [game kicked-player])
(define-struct end-event [game kicked-players])
(define fish-game-event? (or/c start-event? place-event? move-event? kick-event? end-event?))

;; A FishGameEvent is one of:
;; - (make-start-event board? (list-of penguin-color?))
;; - (make-place-event state? posn? penguin-color?)
;; - (make-move-event game-tree? move? penguin-color?)
;; - (make-kick-event game-tree? penguin-color?)
;; - (make-end-event end-game? (list-of penguin-color?))

;; A FishGameEvent represents an event occurring for a game of Fish.
;; There are 5 possible events:
;; - A game is begins
;;   - represented by a start-event with the starting board and the starting list of player colors
;;     participating in the game.
;; - A player places a penguin
;;   - represented by a place-event, with a current state (after the placement), position the penguin
;;     was placed at, and color of the player who placed the penguin.
;; - A player moves a penguin
;;   - represented by a move-event, with a current game tree (after the move), the move that was made,
;;     and the color of the player who made the move.
;; - A player is kicked from the game
;;   - represented by a kick-event, with the current game tree (after the player has been kicked and
;;     their penguins removed), and the color of the penguin who was kicked.
;; - A game ends
;;   - represented by an end-event, with a final game node and a list of player colors that were
;;     kicked from the game.

;; A Standing is a (hash (is-a?/c player-interface) posint?)
(define standing? (hash/c (is-a?/c player-interface) posint?))
;; Representing the standing of a Fish tournament.
;; Each key in a Standing is an object implementing the player interface, and the corresponding value
;; is a positive integer representing that player's rank in the tournament, where 1 is the player in
;; 1st place.
;; In the case of a tie, multiple players may have the same ranking. However, the next ranking(s)
;; will skipped to properly accommodate "missing" rankings due to ties. For example, in a 4-player
;; tournament with P1-P5 where P1 is first, P2/P3/P4 are tied for 2nd, and P4 is following, the
;; Standing would be:
;; (hash P1 1
;;       P2 2
;;       P3 2
;;       P4 2
;;       P5 5)

(define game-observer-interface
  (interface ()
    ;; observe : fish-game-event? -> void?
    ;; Observes the FishGameEvent. The implementer can decide if and how this information is relevant
    ;; Notes:
    ;; - Called by the Referee on all Game Observers each time any FishGameEvent occurs.
    [observe (->m fish-game-event? void?)]))
(define game-observer? (is-a?/c game-observer-interface))

;; A TournamentEvent is a (list Standing (listof FishGameEvent))
(define tournament-event? (list/c standing? (listof fish-game-event?)))
;; Where the Standing represents each player's current rank in the tournament (where ties may be
;; possible), and the (listof FishGameEvent) is the ordered series of FishGameEvents returned by
;; the most recently completed game of Fish where earlier FishGameEvents appear at the start of the
;; list.

(define tournament-observer-interface
  (interface ()
    ;; observe : tournament-event? -> void?
    ;; Observes the TournamentEvent. The implementer can decide if and how this information is
    ;; relevant
    ;; Notes:
    ;; - Called by the Tournament Manager on all Tournament Observers each time any game of Fish
    ;;   concludes.
    [observe (->m tournament-event? void?)]))
(define tournament-observer? (is-a?/c tournament-observer-interface))
