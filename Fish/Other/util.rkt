#lang racket/base

(require json
         racket/pretty
         rackunit)

(provide check-integration)

;; check-integration : [void? -> void?] path-string? path-string? -> void?
;; Pipes the JSON contents of the in-file to STDIN, calls the given function, and checks if the output
(define-check (check-integration fn in-file out-file)
  (define input-json (read-json (open-input-file in-file)))
  (define output-json (read-json (open-input-file out-file)))
  (define captured-json
    (let-values ([(captured-output redirect-out) (make-pipe #f 'read-stdout 'stdout)])
      (parameterize ([current-input-port (open-input-file in-file)]
                     [current-output-port redirect-out])
        (fn)
        (read-json captured-output))))
  (with-check-info (['input (string-info (pretty-format input-json))])
    (check-equal? captured-json output-json)))

