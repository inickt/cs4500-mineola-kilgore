#! /bin/sh
#|
exec racket -tm "$0" -- ${1+"$@"}
|#

#lang racket/base

(require json
         racket/contract
         racket/list
         racket/string)

(provide main)

(define (main name size)
  (generate-json-file name (string->number size)))

(define (generate-json)
    (contract-random-generate
     (or/c
      exact-integer?
      (and/c inexact-real? rational?)
      boolean?
      ;string?
      (symbols (json-null))
      (listof (or/c
               exact-integer?
               (and/c inexact-real? rational?)
               boolean?
               ;string?
               (symbols (json-null))
               (listof (or/c
                        exact-integer?
                        (and/c inexact-real? rational?)
                        boolean?
                        ;string?
                        (symbols (json-null))))
               (hash/c symbol? (or/c
                                exact-integer?
                                (and/c inexact-real? rational?)
                                boolean?
                                ;string?
                                (symbols (json-null))
                                (listof (or/c
                                         exact-integer?
                                         (and/c inexact-real? rational?)
                                         boolean?
                                         ;string?
                                         (symbols (json-null))))))))
      (hash/c symbol? (or/c
                       exact-integer?
                       (and/c inexact-real? rational?)
                       boolean?
                       ;string?
                       (symbols (json-null))
                       (listof (or/c
                                exact-integer?
                                (and/c inexact-real? rational?)
                                boolean?
                                ;string?
                                (symbols (json-null))))
                       (hash/c symbol? (or/c
                                        exact-integer?
                                        (and/c inexact-real? rational?)
                                        boolean?
                                        ;string?
                                        (symbols (json-null))
                                        (listof (or/c
                                                 exact-integer?
                                                 (and/c inexact-real? rational?)
                                                 boolean?
                                                 ;string?
                                                 (symbols (json-null)))))))))))

(define (generate-json-file name size)
  (define file (open-output-file name))
  (for ([i size])
    (write-json (generate-json) file)
    (newline file))
  (flush-output file))
