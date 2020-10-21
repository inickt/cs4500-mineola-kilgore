#lang racket/base

(require lang/posn
         json
         racket/list
         racket/contract
         "board.rkt")

(provide (contract-out [parse-json-board-posn (-> (hash/c symbol? jsexpr?) board-posn?)])
         (contract-out [board-posn-board (-> board-posn? board?)])
         (contract-out [board-posn-posn (-> board-posn? posn?)]))

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
;; TODO
;; JSON: State
(define (parse-json-state json-obj)
  (make-state
   (parse-json-board (hash-ref json-obj BOARD-KEY))
   (parse-json-players (hash-ref json-obj PLAYERS-KEY))))

;; parse-json-players : (non-empty-listof (hash/c symbol? jsexpr?)) -> (non-empty-listof player?)
;; TODO
;; JSON: Player*
(define (parse-json-players json-players)
  (map parse-json-players json-players))

;; parse-json-player : (hash/c symbol? jsexpr?) -> player?
;; TODO
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
;; NOTE: This is the same thing as a transpose of a matrix
;; JSON: Board
(define (parse-json-board json-board)
  (transpose json-board))

;; parse-json-posns : (listof (list/c natural? natural?)) -> (listof posn?)
;; TODO
;; JSON: [Position]
(define (parse-json-posns json-posns)
  (map parse-json-posn json-posns))

;; parse-json-posn : (list/c natural? natural?) -> posn?
;; Parses a (column, row) posn from a well formed and valid (list row column)
;; JSON: Position
(define (parse-json-posn json-posn)
  (make-posn (second json-posn) (first json-posn)))

;; parse-json-color : string? -> penguin?
;; TODO
;; JSON: Color
(define (parse-json-color json-color)
  (string->symbol (string-upcase json-color)))

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED SERIALIZING

#|

;; parse-json-state : state? -> (hash/c jsexpr?)
;; TODO
;; JSON: State
(define (parse-json-state json-obj)
  (make-state
   (parse-json-board (hash-ref json-obj BOARD-KEY))
   (parse-json-players (hash-ref json-obj PLAYERS-KEY))))

;; serialize-players : (non-empty-listof player?) -> (non-empty-listof (hash/c symbol? jsexpr?))
;; TODO
;; JSON: Player*
(define (serialize-players players)
  (map serialize-player players))

;; serialize-player : player? -> (hash/c symbol? jsexpr?)
;; TODO
;; JSON: Player
(define (serialize-player player)
  (make-player
   (parse-json-color (hash-ref json-player COLOR-KEY))
   (hash-ref json-player SCORE-KEY)
   (parse-json-posns (hash-ref json-player PLACES-KEY))))

;; serialize-board : board? -> (non-empty-listof (non-empty-listofnatural?)) 
;; TODO
;; JSON: Board
(define (serialize-board board)
  (transpose board))

;; serialize-posns : (listof posn?) -> (listof (list/c natural? natural?))
;; TODO
;; JSON: [Position]
(define (parse-json-posns json-posns)
  (map parse-json-posn json-posns))

;; serialize-posn : posn? -> (list/c natural? natural?)
;; 
;; JSON: Position
(define (serialize-posn posn)
  (make-posn (second json-posn) (first json-posn)))

;; serialize-color : penguin? -> string?
;; TODO
;; JSON: Color
(define (serialize-color penguin)
  (string-downcase (symbol->string penguin)))

|#

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
  ;; parse-json-board-posn
  (check-equal? (parse-json-board-posn (hash POSITION-KEY '(6 0)
                                             BOARD-KEY '((1 2 3) (4 5 6) (7 8 9))))
                (make-board-posn '((1 4 7) (2 5 8) (3 6 9))
                                 (make-posn 0 6)))
  ;; parse-json-board
  (check-equal? (parse-json-board '((1))) '((1)))
  (check-equal? (parse-json-board '((1 2 3) (4 5 6) (7 8 9))) '((1 4 7) (2 5 8) (3 6 9)))
  ;; parse-json-posn
  (check-equal? (parse-json-posn '(1 4)) (make-posn 4 1))
  (check-equal? (parse-json-posn '(6 0)) (make-posn 0 6)))