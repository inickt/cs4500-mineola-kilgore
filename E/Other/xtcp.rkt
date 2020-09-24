#lang racket/base

(require json
         racket/bool
         racket/list
         racket/port
         racket/string
         racket/tcp
         rackunit)

(provide xtcp)

;+---------------------------------------------------------------------------------------------------+
; Constants

(define DEFAULT-PORT 4567)
(define TIMEOUT 3)

(define CNT 'count)
(define SEQ 'seq)

(define TEST-JSON '(1 "a" #hasheq((hello . "world")) #hasheq((outer . #hasheq((inner . "layer"))))))
(define TEST-JSON-STR "1 \"a\" {\"hello\": \"world\"} {\"outer\": {\"inner\": \"layer\"}}")

;+---------------------------------------------------------------------------------------------------+
; Functions

;; read-input : input-port? -> (listof jsexpr?)
;; Build list of json expressions from the input port until EOF
(define (read-input port)
  (define json-obj (read-json port))
  (if (eof-object? json-obj) '() (cons json-obj (read-input port))))
(check-equal? (read-input (open-input-string "")) '())
(check-equal? (read-input (open-input-string "1")) '(1))
(check-equal? (read-input (open-input-string TEST-JSON-STR)) TEST-JSON)

;; count-seq : (listof jsexpr?) -> (hash/c symbol? jsexpr?)
;; Create a hashmap with the count and original sequence
(define (count-seq json-list)
  (hash
   CNT (length json-list)
   SEQ json-list))
(check-equal? (count-seq '()) (hash CNT 0 SEQ '()))
(check-equal? (count-seq TEST-JSON) (hash CNT 4 SEQ TEST-JSON))

;; count-and-reverse : (listof jsexpr?) -> (listof jsexpr?)
;; Cons the number of json objects to the reversed list
(define (count-and-reverse json-list)
  (cons
   (length json-list)
   (reverse json-list)))
(check-equal? (count-and-reverse '()) '(0))
(check-equal? (count-and-reverse TEST-JSON) (cons 4 (reverse TEST-JSON)))

;; xjson : input-port? output-port? -> void?
;; Read json from the input port until EOF, then write two json objects
;; - A json object with the count of json objects and the orignal sequence
;; - A json list with the count as the first element and the json sequence in reversed order
(define (xjson in out)
  (define json-list (read-input in))
  (write-json (count-seq json-list) out)
  (newline out)
  (write-json (count-and-reverse json-list) out)
  (newline out))
(check-equal?
 (with-output-to-string (λ () (xjson (open-input-string "") (current-output-port))))
 "{\"count\":0,\"seq\":[]}\n[0]\n")
(check-equal?
 (map string->jsexpr
      (string-split
       (with-output-to-string (λ () (xjson (open-input-string TEST-JSON-STR) (current-output-port))))
       "\n"))
 (list (hasheq CNT 4 SEQ TEST-JSON)
       (cons 4 (reverse TEST-JSON))))

;; xtcp : listen-port-number? -> void?
;; Read json stream from a TCP connection, writes json objects produced from xjson
(define (xtcp [port DEFAULT-PORT])
  ; make a custodian to close tcp connection and its input/output ports
  ; not using current-custodian since it will close the repl
  (parameterize ([current-custodian (make-custodian)])
    ; result : (or/c false? (list/c input-port? output-port?))
    (define result (sync/timeout TIMEOUT (tcp-accept-evt (tcp-listen port))))
    ; handle timeout
    (when (false? result)
      (custodian-shutdown-all (current-custodian))
      (error "Timed out waiting for connection"))
    ; handle connection
    (xjson (first result) (second result))
    (custodian-shutdown-all (current-custodian))))
