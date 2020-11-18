#lang racket/base

(require json
         racket/class
         racket/list
         racket/match
         "../../Fish/Admin/referee-interface.rkt"
         "../../Fish/Admin/referee.rkt"
         "../../Fish/Common/json.rkt"
         "../../Fish/Player/player.rkt")

(provide xref)

;; +-------------------------------------------------------------------------------------------------+
;; PROVIDED

;; xref : -> void?
;; Read a JSON Game Description from STDIN, runs a game, and outputs the winners written to STDOUT
(define (xref)
  (write-json
   (match (parse-json-game-description (read-json))
     [(game-description r c p f) (xref-helper r c p f)]))
  (newline))

;; +-------------------------------------------------------------------------------------------------+
;; INTERNAL HELPER FUNCTIONS

;; xref-helper : 
;; (integer-in 2 5) (integer-in 2 5) (listof (list/c string? (integer-in 1 2))) (integer-in 1 5)
;;  -> (listof string?)
;; runs a game with the specified number of players on a "row" by "column" board with each tile 
;;   populated by the given number of fish 
(define (xref-helper rows columns players fish)
  (define player-interfaces (map (λ (player-depth) (new player% [depth (second player-depth)]))
                                 players))
  (define players-to-names
    (for/hasheq ([player-depth players]
                 [player-interface player-interfaces])
      (values player-interface (first player-depth))))

  ;; INVARIENT: Our own players won't be kicked, so we don't bother checking the kicked players
  (define players-and-scores
    (first (send (new referee%) run-game player-interfaces 
                 (make-board-options columns rows fish) 
                 '())))
  (find-winners players-and-scores players-to-names))

;; find-winners : (non-empty-listof player-score?) (hasheq/c player-interface? string?)
;;                -> (listof string?)
;; Get the names of the winners from their scores, in alphabetical order
(define (find-winners players-and-scores players-to-names)
  (define max-score (second (argmax second players-and-scores)))
  (define winning-players (filter (λ (player-and-score) (= (second player-and-score) max-score))
                                  players-and-scores))
  (define winner-names 
    (map (λ (player-and-score) (hash-ref players-to-names (first player-and-score))) winning-players))
  (sort winner-names string<=?))

;; +-------------------------------------------------------------------------------------------------+
;; TESTS
(module+ test
  (require rackunit
           "../../Fish/Other/util.rkt")

  ;; +--- xref-helper ---+
  ;; Board is stuck - no one goes and everyone ties
  (check-equal? (xref-helper 4 2 '(("appa" 1) ("bo" 1)) 3) '("appa" "bo"))
  ;; Both players can move once and get 1 fish
  (check-equal? (xref-helper 5 2 '(("appa" 1) ("bo" 1)) 3) '("appa" "bo"))
  ;; All players move the same way down the map
  (check-equal? (xref-helper 5 3 '(("appa" 1) ("bo" 1) ("cat" 1)) 3) '("appa" "bo" "cat"))
  ;; Odd number of tiles. P1 gets extra
  (check-equal? (xref-helper 5 3 '(("appa" 1) ("bo" 1)) 3) '("appa"))
  ;; 16-9=7 open tiles, P1 gets te extra
  (check-equal? (xref-helper 4 4 '(("appa" 1) ("bo" 1) ("cat" 1)) 3) '("appa"))
  ;; Same as previous, but P2 is smart
  (check-equal? (xref-helper 4 4 '(("appa" 1) ("bo" 2) ("cat" 1)) 3) '("bo"))

  ;; +--- find-winners ---+
  (define p1 (new player%))
  (define p2 (new player%))
  (define p3 (new player%))
  (define p4 (new player%))
  (define names (hasheq p1 "p1" p2 "p2"  p3 "p3" p4 "p4"))

  (check-equal? (find-winners (list (list p2 1)
                                    (list p1 4)
                                    (list p3 2)
                                    (list p4 3))
                              names)
                (list "p1"))
  (check-equal? (find-winners (list (list p4 4)
                                    (list p2 1)
                                    (list p1 4)
                                    (list p3 2))
                              names)
                (list "p1" "p4"))
  (check-equal? (find-winners (list (list p2 4)
                                    (list p1 4)
                                    (list p3 4)
                                    (list p4 4))
                              names)
                (list "p1" "p2" "p3" "p4"))

  ;; Integration tests
  ;; all winners - no moves and game ends immediately
  (check-integration xref "../Tests/1-in.json" "../Tests/1-out.json")
  ;; all dumb and move the same way, but only 2/3 win
  (check-integration xref "../Tests/2-in.json" "../Tests/2-out.json")
  ;; some interesting example with depth actually making a difference
  (check-integration xref "../Tests/3-in.json" "../Tests/3-out.json"))
