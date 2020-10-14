#lang racket/base

(require 2htdp/image
         lang/posn
         racket/contract
         racket/format
         racket/list
         "board.rkt"
         "penguin.rkt")

;; +-------------------------------------------------------------------------------------------------+
;; DATA DEFINITIONS

(define-struct state [board penguins players order])
(define penguins? (hash/c penguin? (listof posn?)))
;; A GameState is a:
;; (make-state board? penguins? (listof player?) (non-empty-listof penguin?))
;; And represents a fish game state, containing:
;; - the current board state
;; - the current positions of penguins on the board
;; - the current players and their penguins
;; - the order of the players' turns, denoted by their color
;; INVARIANT: state-order is an ordered list, with the first being the current
;;            players turn, second being the turn after the first, and so on...

(define-struct player [age color])
;; A Player is a (make-player natural? penguin-color?)
;; and represents a player in a fish game with their age in years and penguin color

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : [2,4] ... -> state?
;;
#;
(define (create-game players ...)
  ...)

;; place-penguin : posn? state? -> state?
;; Places the current player's penguin on the board at the given position.
;; NOTE: Does not check number of penguins a player has placed. We think this should be
;;       handled by the game rules
(define (place-penguin posn state)
  (when (not (valid-tile? posn (state-board state)))
    (raise-argument-error 'place-penguin
                          (~a posn " is either a hole or not on the board")
                          0))
  (when (member posn (hash-values (state-penguins state)))
    (raise-argument-error 'place-penguin
                          (~a "There is already a penguin at " posn)
                          0))
  (make-state (state-board state)
              (add-penguin-posn (state-penguins state) (first (state-order state)) posn)
              (state-players state)
              (shift-turn-order (state-order state))))

;; move-pegnuin : penguin? posn? state? -> state?
;;
#;
(define (move-penguin penguin posn state)
  ...)

;; can-move? : player? posn? state? -> state?
;;
#;
(define (can-move? player posn state)
  (and (penguin=? (first (state-order state)) (player-color player))
       ;;
       ...))

;; draw-state : state? natural? -> image?
;; Draws a game state at the given width
#;
(define (draw-state state width)
  ...)

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL

;; shift-turn-order : (non-empty-listof penguin?) -> (non-empty-listof penguin?)
;; Moves 
(define (shift-turn-order order)
  (append (rest order) (list (first order))))

;; penguins-per-player : (listof player?) -> natural?
(define (penguins-per-player players)
  (- 6 (length players)))

;; add-penguin-posn : penguins? penguin? posn?  -> penguins?
;; Adds the given position to the given penguin's positions
(define (add-penguin-posn penguin-posns penguin posn)
  (hash-update penguin-posns
               penguin
               (λ (posns) (cons posn posns))
               '()))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS

(module+ test
  (require rackunit)
  ;; Testing Helpers
  ;; Provided Functions
  ;; place-penguin
  

  ;; Internal Helper Functions
  ;; shift-turn-order
  (check-equal? (shift-turn-order '(black white)) '(white black))
  (check-equal? (shift-turn-order '(black white red)) '(white red black))
  (check-equal? (shift-turn-order '(black white red brown)) '(white red brown black))

  ;; penguins-per-player

  ;; add-penguin-posn
  (check-equal? (add-penguin-posn
                 (hash 'RED (list (make-posn 0 0))
                       'WHITE (list (make-posn 1 1))
                       'BROWN (list (make-posn 0 1)))
                 'BLACK
                 (make-posn 1 0))
                (hash 'RED (list (make-posn 0 0))
                      'WHITE (list (make-posn 1 1))
                      'BROWN (list (make-posn 0 1))
                      'BLACK (list (make-posn 1 0))))
  (check-equal? (add-penguin-posn
                 (hash 'RED (list (make-posn 2 4) (make-posn 0 3))
                       'WHITE (list (make-posn 1 1) (make-posn 3 0))
                       'BROWN (list (make-posn 0 1) (make-posn 3 3))
                       'BLACK (list (make-posn 1 0) (make-posn 2 2)))
                 'WHITE
                 (make-posn 1 3))
                (hash 'RED (list (make-posn 2 4) (make-posn 0 3))
                      'WHITE (list (make-posn 1 3) (make-posn 1 1) (make-posn 3 0))
                      'BROWN (list (make-posn 0 1) (make-posn 3 3))
                      'BLACK (list (make-posn 1 0) (make-posn 2 2))))
  )
