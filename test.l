#!/usr/bin/env pil

(load (pack (car (file)) ".modules/picolisp-unit/HEAD/unit.l"))

(load (pack (car (file)) "mqueue.l"))

(prinl "^J  Testing POSIX Message Queues for PicoLisp^J")
(prin "  Testing with PicoLisp: ")
(version)
(prinl)

(chdir "test/"
  (mapcar load (filter '((N) (sub? "test_" N)) (dir "."))) )

(report)
