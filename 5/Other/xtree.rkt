#lang racket/base

(require lang/posn
         json
         racket/list
         "../../Fish/Common/json.rkt"
         "../../Fish/Common/game-tree.rkt")

(provide xtree)

(define (xtree)
  (define move-response-query (parse-json-state (read-json)))
  (define state (move-response-query-state move-response-query))
  (define move (move-response-query-move move-response-query))
  ;(define game (make-game state))

  #;
  (unless (is-valid-move? game move)
    (error "Move provided is invalid, should be well formed"))

  ;(define moved-game (apply-move game move))

  ;; apply move in game created from state
  ;; get all valid moves after player picked position
  ;; next player picks move
  ;; - (valid-moves posn state) <- using posn player moved to and that state,
  ;;   find move(s) in hypothetical game that are the first in valid-moves
  
  ;(define result-state (get-result-state penguin cur-posn state))
  ;(if result-state (write-json (serialize-state result-state)) (write-json #false))
  (newline))