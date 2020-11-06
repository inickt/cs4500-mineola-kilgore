#lang racket/base

(require racket/class
         racket/contract)

(provide start-event
         place-event
         move-event
         kick-event
         end-event
         fish-game-event?
         game-observer-interface)

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

(define game-observer-interface
  (interface ()
    ;; observe : fish-game-event? -> void?
    ;; Observes the FishGameEvent. The implementer can decide if and how this information is relevant
    ;; Notes:
    ;; - Called by the Referee on all observers each time any FishGameEvent occurs.
    [observe (->m fish-game-event? void?)]))
