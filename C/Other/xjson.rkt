#lang racket/base

(require json
         racket/string
         racket/port
         rackunit)

(provide xjson)

;+---------------------------------------------------------------------------------------------------+
; Constants

(define CNT 'count)
(define SEQ 'seq)

(define TEST-JSON '(1 "a" #hasheq((hello . "world")) #hasheq((outer . #hasheq((inner . "layer"))))))
(define TEST-JSON-STR "1 \"a\" {\"hello\": \"world\"} {\"outer\": {\"inner\": \"layer\"}}")

;+---------------------------------------------------------------------------------------------------+
; Functions

; read-input: -> [Listof jsexpr?]
; Build list of json expressions from inputs until EOF
(define (read-input)
  (define json-obj (read-json))
  (if (eof-object? json-obj) '() (cons json-obj (read-input))))
(check-equal? (with-input-from-string "" read-input) '())
(check-equal? (with-input-from-string "1" read-input) '(1))
(check-equal? (with-input-from-string TEST-JSON-STR read-input) TEST-JSON)

; count-seq: [Listof jsexpr?] -> [Hashof symbol? jsexpr?]
; Create a hashmap with the count and original sequence
(define (count-seq json-list)
  (hash
   CNT (length json-list)
   SEQ json-list))
(check-equal? (count-seq '()) (hash CNT 0 SEQ '()))
(check-equal? (count-seq TEST-JSON) (hash CNT 4 SEQ TEST-JSON))

; count-and-reverse: [Listof jsexpr?] -> [Listof jsexpr?]
; Cons the number of json objects to the reversed list
(define (count-and-reverse json-list)
  (cons
   (length json-list)
   (reverse json-list)))
(check-equal? (count-and-reverse '()) '(0))
(check-equal? (count-and-reverse TEST-JSON) (cons 4 (reverse TEST-JSON)))

; xjson: -> void?
; Read json from STDIN until EOF, then write two json objects
; - A json object with the count of json objects and the orignal sequence
; - A json list with the count as the first element and the json sequence in reversed order
(define (xjson)
  (define json-list (read-input))
  (write-json (count-seq json-list))
  (newline)
  (write-json (count-and-reverse json-list))
  (newline))
(check-equal?
 (with-output-to-string (λ () (with-input-from-string "" xjson)))
 "{\"count\":0,\"seq\":[]}\n[0]\n")
(check-equal?
 (map string->jsexpr
      (string-split (with-output-to-string (λ () (with-input-from-string TEST-JSON-STR xjson))) "\n"))
 (list (hasheq CNT 4 SEQ TEST-JSON)
       (cons 4 (reverse TEST-JSON))))
