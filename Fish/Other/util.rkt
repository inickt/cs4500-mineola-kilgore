#lang racket/base

(require json
         racket/pretty
         rackunit)

(provide check-integration
         check-fest)

;; check-integration : [void? -> void?] path-string? path-string? -> void?
;; Pipes the JSON contents of the in-file to STDIN, calls the given function, and checks if the output
(define-check (check-integration fn in-file out-file)
  (parameterize ([current-custodian (make-custodian)])
    (define input-json (read-json (open-input-file in-file)))
    (define output-json (read-json (open-input-file out-file)))
    (define captured-json
      (let-values ([(captured-output redirect-out) (make-pipe #f 'read-stdout 'stdout)])
        (parameterize ([current-input-port (open-input-file in-file)]
                       [current-output-port redirect-out])
          (fn)
          (read-json captured-output))))
    (with-check-info (['input (string-info (pretty-format input-json))])
      (check-equal? captured-json output-json))
    (custodian-shutdown-all (current-custodian))))

;; check-fest :  [void? -> void?] path-string? -> void?
;; Runs all test inputs and outputs found in [fest-path]/*/*-[in|out].json using check-integration
;; NOTE: Assumes tests are valid JSON and are correct tests
(define (check-fest fn fest-path)
  (for* ([repo (directory-list fest-path)]
         #:when (directory-exists? (build-path fest-path repo))
         ;; TODO: should just use globbing
         [test-number (build-list 30 add1)]
         ;; TODO: should clean this up
         [input-path (in-value (build-path fest-path
                                           repo
                                           "Tests"
                                           (string-append (number->string test-number)
                                                          "-in.json")))]
         [output-path (in-value (build-path fest-path
                                            repo
                                            "Tests"
                                            (string-append (number->string test-number)
                                                           "-out.json")))]
         #:when (and (file-exists? input-path) (file-exists? output-path)))
    (test-case (path->string input-path)
               (check-integration fn input-path output-path))))
