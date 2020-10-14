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

(define-struct state [board penguins players removed-players order])
(define penguins? (hash/c penguin? (listof posn?)))
;; A GameState is a:
;; (make-state board? penguins? (listof player?) (listof player?) (non-empty-listof penguin?))
;; And represents a fish game state, containing:
;; - the current board state
;; - the current positions of penguins on the board
;; - the current players and their penguin color
;; - players removed from the game
;; - the order of the players' turns, denoted by their color
;; INVARIANT: the length of players and removed-players is the same the whole duration of the game
;; INVARIANT: state-order is an ordered list, with the first being the current
;;            players turn, second being the turn after the first, and so on...

(define-struct player [age color score])
;; A Player is a (make-player natural? penguin-color? natural?)
;; and represents a player in a fish game with their age in years, penguin color, and score

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; create-game : (list natural? ...) board? -> state?
;;
(define (create-game player-ages board)
  (define num-players (length player-ages))
  (define colors (take (shuffle PENGUIN-COLORS) num-players))
  (define players (map make-player (sort player-ages <) colors (make-list num-players 0)))
  (make-state board #hash() players '() (map player-color players)))

;; place-penguin : posn? state? -> state?
;; Places the current player's penguin on the board at the given position.
(define (place-penguin posn state)
  (when (not (valid-tile? posn (state-board state)))
    (raise-argument-error 'place-penguin
                          (~a posn " is either a hole or not on the board")
                          0))
  (when (member posn (hash-values (state-penguins state)))
    (raise-argument-error 'place-penguin
                          (~a "There is already a penguin at " posn)
                          0))
  (when (>= (length (hash-ref (state-penguins state)
                              (first (state-order state))
                              '()))
            (penguins-per-player state))
    (raise-argument-error 'place-penguin
                          (~a "The current player has already placed all of their penguins")
                          1))
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

;; penguins-per-player : state? -> natural?
;; Total numbers of penguins a player can have in a game 
(define (penguins-per-player state)
  (- 6 (+ (length (state-players state))
          (length (state-removed-players state)))))

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
