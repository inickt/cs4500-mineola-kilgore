#lang racket/base

(require lang/posn
         json
         racket/contract
         racket/list
         "board.rkt"
         "penguin.rkt"
         "state.rkt")

(provide (contract-out [parse-json-state (-> (hash/c symbol? jsexpr?) state?)])
         (contract-out [parse-json-board-posn (-> (hash/c symbol? jsexpr?) board-posn?)])
         (contract-out [board-posn-board (-> board-posn? board?)])
         (contract-out [board-posn-posn (-> board-posn? posn?)])
         (contract-out [serialize-state (-> state? (hash/c symbol? jsexpr?))]))

;; +-------------------------------------------------------------------------------------------------+
;; CONSTANTS

(define BOARD-KEY 'board)
(define COLOR-KEY 'color)
(define PLACES-KEY 'places)
(define PLAYERS-KEY 'players)
(define POSITION-KEY 'position)
(define SCORE-KEY 'score)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED PARSING

;; parse-json-state : (hash/c symbol? jsexpr?) -> state?
;; Parses a Fish game state from well formed and valid JSON
;; JSON: State
(define (parse-json-state json-obj)
  (make-state
   (parse-json-board (hash-ref json-obj BOARD-KEY))
   (parse-json-players (hash-ref json-obj PLAYERS-KEY))))

;; parse-json-players : (non-empty-listof (hash/c symbol? jsexpr?)) -> (non-empty-listof player?)
;; Parses Fish players from well formed and valid JSON
;; JSON: Player*
(define (parse-json-players json-players)
  (map parse-json-player json-players))

;; parse-json-player : (hash/c symbol? jsexpr?) -> player?
;; Parses a Fish player from well formed and valid JSON
;; JSON: Player
(define (parse-json-player json-player)
  (make-player
   (parse-json-color (hash-ref json-player COLOR-KEY))
   (hash-ref json-player SCORE-KEY)
   (parse-json-posns (hash-ref json-player PLACES-KEY))))

(define-struct board-posn [board posn] #:transparent)
;; parse-json-board-posn : (hash/c symbol? jsexpr?) -> board-posn?
;; Parses a Fish game board and position from a well formed JSON
;; JSON: Board-Posn
(define (parse-json-board-posn json-obj)
  (make-board-posn
   (parse-json-board (hash-ref json-obj BOARD-KEY))
   (parse-json-posn (hash-ref json-obj POSITION-KEY))))

;; parse-json-board : (non-empty-listof (non-empty-listofnatural?)) -> board?
;; Parses a Fish game board from a well formed and valid JSON board
;; NOTE: The lists can potentially be different lengths. This function will find the longest length
;;       of these lists and fill the remainder of the board with holes.
;;       https://piazza.com/class/kevisd7ggfb502?cid=246_f1
;; JSON: Board
(define (parse-json-board json-board)
  (define longest (apply max (map length json-board)))
  (define padded-json-board (map (λ (tiles) (append tiles (make-list (- longest (length tiles)) 0)))
                                 json-board))
  (transpose-matrix padded-json-board))

;; parse-json-posns : (listof (list/c natural? natural?)) -> (listof posn?)
;; Parses Fish positions from well formed and valid JSON
;; JSON: [Position]
(define (parse-json-posns json-posns)
  (map parse-json-posn json-posns))

;; parse-json-posn : (list/c natural? natural?) -> posn?
;; Parses a (column, row) posn from a well formed and valid (list row column)
;; JSON: Position
(define (parse-json-posn json-posn)
  (make-posn (second json-posn) (first json-posn)))

;; parse-json-color : string? -> penguin?
;; Parses a Fish color from well formed and valid JSON
;; JSON: Color
(define parse-json-color string->symbol)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED SERIALIZING

;; serialize-state : state? -> (hash/c (symbol? jsexpr?)
;; Converts a state into a JSON expression
;; JSON: State
(define (serialize-state state)
  (hash BOARD-KEY (serialize-board (state-board state))
        PLAYERS-KEY (serialize-players (state-players state))))

;; serialize-players : (non-empty-listof player?) -> (non-empty-listof (hash/c symbol? jsexpr?))
;; Converts players into a JSON expression
;; JSON: Player*
(define (serialize-players players)
  (map serialize-player players))

;; serialize-player : player? -> (hash/c symbol? jsexpr?)
;; Converts a player into a JSON expression
;; JSON: Player
(define (serialize-player player)
  (hash COLOR-KEY (serialize-color (player-color player))
        SCORE-KEY (player-score player)
        PLACES-KEY (serialize-posns (player-places player))))

;; serialize-board : board? -> (non-empty-listof (non-empty-listofnatural?)) 
;; Converts a board into a JSON expression
;; JSON: Board
(define serialize-board (λ (board) (transpose-matrix board)))

;; serialize-posns : (listof posn?) -> (listof (list/c natural? natural?))
;; Converts posns into a JSON expression
;; JSON: [Position]
(define (serialize-posns posns)
  (map serialize-posn posns))

;; serialize-posn : posn? -> (list/c natural? natural?)
;; Converts a posn into a JSON expression
;; JSON: Position
(define (serialize-posn posn)
  (list (posn-y posn) (posn-x posn)))

;; serialize-color : penguin? -> string?
;; Converts a penguin into a JSON expression
;; JSON: Color
(define serialize-color symbol->string)

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS

;; transpose-matrix : (non-empty-listof (non-empty-listof any/c)) -> (listof (listof any/c))
;; Transposes a matrix represented as a 2d list
(define (transpose-matrix mat)
  (apply map list mat))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require rackunit)
  
  ;; Provided Functions
  ;; parse-json-state 
  (check-equal? (parse-json-state
                 (hash BOARD-KEY '((1 2 3) (4 5 6) (7 8 9))
                       PLAYERS-KEY (list (hash COLOR-KEY "red"
                                               SCORE-KEY 10
                                               PLACES-KEY '())
                                         (hash COLOR-KEY "black"
                                               SCORE-KEY 5
                                               PLACES-KEY (list (list 0 0) (list 3 1))))))
                (make-state '((1 4 7) (2 5 8) (3 6 9))
                            (list (make-player RED 10 '())
                                  (make-player BLACK 5 (list (make-posn 0 0) (make-posn 1 3))))))
  ;; parse-json-players
  (check-equal? (parse-json-players (list (hash COLOR-KEY "red"
                                                SCORE-KEY 10
                                                PLACES-KEY '())
                                          (hash COLOR-KEY "black"
                                                SCORE-KEY 5
                                                PLACES-KEY (list (list 0 0) (list 3 1)))))
                (list (make-player RED 10 '())
                      (make-player BLACK 5 (list (make-posn 0 0) (make-posn 1 3)))))
  ;; parse-json-player
  (check-equal? (parse-json-player (hash COLOR-KEY "red"
                                         SCORE-KEY 10
                                         PLACES-KEY '()))
                (make-player RED 10 '()))
  (check-equal? (parse-json-player (hash COLOR-KEY "black"
                                         SCORE-KEY 5
                                         PLACES-KEY (list (list 0 0) (list 3 1))))
                (make-player BLACK 5 (list (make-posn 0 0) (make-posn 1 3))))
  ;; parse-json-board-posn
  (check-equal? (parse-json-board-posn (hash POSITION-KEY '(6 0)
                                             BOARD-KEY '((1 2 3) (4 5 6) (7 8 9))))
                (make-board-posn '((1 4 7) (2 5 8) (3 6 9))
                                 (make-posn 0 6)))
  ;; parse-json-board
  (check-equal? (parse-json-board '((1))) '((1)))
  (check-equal? (parse-json-board '((1 2 3) (4 5 6) (7 8 9))) '((1 4 7) (2 5 8) (3 6 9)))
  ;; example of uneven board filled with holes
  (check-equal? (parse-json-board '((1 2 3) (4) (7 8 9 1))) '((1 4 7) (2 0 8) (3 0 9) (0 0 1)))
  ;; parse-json-posns
  (check-equal? (parse-json-posns '((1 4) (6 0))) (list (make-posn 4 1) (make-posn 0 6)))
  ;; parse-json-posn
  (check-equal? (parse-json-posn '(1 4)) (make-posn 4 1))
  (check-equal? (parse-json-posn '(6 0)) (make-posn 0 6))
  ;; parse-json-color
  (check-equal? (parse-json-color "red") RED)
  (check-equal? (parse-json-color "white") WHITE)
  ;; serialize-state
  (check-equal? (serialize-state
                 (make-state (make-even-board 4 3 1)
                             (list (make-player RED 10 '())
                                   (make-player BLACK 5 (list (make-posn 0 0) (make-posn 1 3))))))
                (hash BOARD-KEY '((1 1 1 1) (1 1 1 1) (1 1 1 1))
                      PLAYERS-KEY (list (hash COLOR-KEY "red"
                                              SCORE-KEY 10
                                              PLACES-KEY '())
                                        (hash COLOR-KEY "black"
                                              SCORE-KEY 5
                                              PLACES-KEY (list (list 0 0) (list 3 1))))))
  ;; serialize-players
  (check-equal? (serialize-players
                 (list (make-player RED 10 '())
                       (make-player BLACK 5 (list (make-posn 0 0) (make-posn 1 3)))))
                (list (hash COLOR-KEY "red"
                            SCORE-KEY 10
                            PLACES-KEY '())
                      (hash COLOR-KEY "black"
                            SCORE-KEY 5
                            PLACES-KEY (list (list 0 0) (list 3 1)))))
  ;; serialize-player
  (check-equal? (serialize-player (make-player RED 10 '()))
                (hash COLOR-KEY "red"
                      SCORE-KEY 10
                      PLACES-KEY '()))
  (check-equal? (serialize-player (make-player BLACK 5 (list (make-posn 0 0) (make-posn 1 3))))
                (hash COLOR-KEY "black"
                      SCORE-KEY 5
                      PLACES-KEY (list (list 0 0) (list 3 1))))
  ;; serialize-board
  (check-equal? (serialize-board (make-even-board 2 2 1))
                '((1 1) (1 1)))
  (check-equal? (serialize-board (make-even-board 4 3 1))
                '((1 1 1 1) (1 1 1 1) (1 1 1 1)))
  ;; serialize-posns
  (check-equal? (serialize-posns '()) '())
  (check-equal? (serialize-posns (list (make-posn 1 1) (make-posn 0 4)))
                (list (list 1 1) (list 4 0)))
  ;; serialize-posn
  (check-equal? (serialize-posn (make-posn 0 0))
                (list 0 0))
  (check-equal? (serialize-posn (make-posn 1 5))
                (list 5 1))
  ;; serialize-color
  (check-equal? (serialize-color RED) "red")
  (check-equal? (serialize-color BLACK) "black")

  ;; ROUND TRIP TEST
  (define test-state (make-state '((1 4 7) (2 5 8) (3 6 0) (1 1 0))
                                 (list (make-player RED 10 '())
                                       (make-player BLACK 5 (list (make-posn 0 0) (make-posn 1 2))))))
  (check-equal? (parse-json-state (serialize-state test-state))
                test-state))