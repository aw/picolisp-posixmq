# Tests for mqueue

(off *PMQ_verbose)

(de test-constants ()
  (assert-kind-of 'Number O_CLOEXEC "[CONSTANTS] Should validate O_CLOEXEC is a number")
  (assert-kind-of 'Number O_RDONLY "[CONSTANTS] Should validate O_RDONLY is a number")
  (assert-kind-of 'Number O_WRONLY "[CONSTANTS] Should validate O_WRONLY is a number")
  (assert-kind-of 'Number O_RDWR "[CONSTANTS] Should validate O_RDWR is a number")
  (assert-kind-of 'Number O_CREAT "[CONSTANTS] Should validate O_CREAT is a number")
  (assert-kind-of 'Number O_EXCL "[CONSTANTS] Should validate O_EXCL is a number")
  (assert-kind-of 'Number O_NONBLOCK "[CONSTANTS] Should validate O_NONBLOCK is a number")
  ]

(de test-types ()
  (assert-equal O_RDONLY (pmq-get-type) "[TYPES] Should validate the type to O_RDONLY (default)")
  (assert-equal O_WRONLY (pmq-get-type NIL T) "[TYPES] Should validate the type to O_WRONLY")
  (assert-equal O_RDWR (pmq-get-type T T) "[TYPES] Should validate the type to O_RDWR")
  ]

(de test-open ()
  (let (Fd1 (pmq-open "/___posixmq-tests1" NIL NIL (list O_CREAT))
        Fd2 (pmq-open "/___posixmq-tests2" T T (list O_CREAT O_NONBLOCK) "0600" 5 10)
        )
    (assert-kind-of 'Number Fd1 "[OPEN] Should validate 'open' returns a file descriptor")
    (assert-kind-of 'Number Fd2 "[OPEN] Should validate 'open' returns a file descriptor (with args)")
    (assert-t (bool (ge0 Fd1)) "[OPEN] Should validate 'open' result is >= 0")
    (assert-t (bool (ge0 Fd2)) "[OPEN] Should validate 'open' result is >= 0 (with args)")
    (assert-equal (list 0 *PMQ_maxmsg *PMQ_msgsize 0) (pmq-getattr Fd1) "[OPEN] Should validate 'open' attributes")
    (assert-equal (list O_NONBLOCK 5 10 0) (pmq-getattr Fd2) "[OPEN] Should validate 'open' attributes (with args)")

    (assert-throws 'pmq-error "Invalid argument" '(pmq-open "invalid-name") "[OPEN] Throws: Invalid argument when the name is invalid")
    (assert-throws 'pmq-error "No such file or directory" '(pmq-open "/___posixmq-tests3") "[OPEN] Throws: No such file or directory when O_CREAT is not given")
    (assert-throws 'pmq-error "File exists" '(pmq-open "/___posixmq-tests1" T T (list O_CREAT O_EXCL)) "[OPEN] Throws: File exists when O_CREAT and O_EXCL are given")
    (assert-throws 'pmq-error "Invalid argument" '(pmq-open "/___posixmq-tests1" T T (list 9000000)) "[OPEN] Throws: Invalid argument when the flags are invalid")
    (assert-throws 'pmq-error "Permission denied" '(pmq-open "/___posixmq/tests1") "[OPEN] Throws: Permission denied when more than one slash '/' is given")
    (assert-throws 'pmq-error "File name too long" '(pmq-open (pack "/___posixmq" (need 255 "a"))) "[OPEN] Throws: File name too long if the queue name is too long")
    (assert-throws 'pmq-error "Invalid argument" '(pmq-open "/___posixmq-tests3" T T (list O_CREAT) "0600" -1 10) "[OPEN] Throws: Invalid argument if the Maxmsg is less than 0")
    (assert-throws 'pmq-error "Invalid argument" '(pmq-open "/___posixmq-tests3" T T (list O_CREAT) "0600" (+ 1 *PMQ_os_msg_max) 10) "[OPEN] Throws: Invalid argument if the Maxmsg is too large")
    (assert-throws 'pmq-error "Invalid argument" '(pmq-open "/___posixmq-tests3" T T (list O_CREAT) "0600" 5 -1) "[OPEN] Throws: Invalid argument if the Msgsize is less than 0")
    (assert-throws 'pmq-error "Invalid argument" '(pmq-open "/___posixmq-tests3" T T (list O_CREAT) "0600" 5 (+ 1 *PMQ_os_msgsize_max)) "[OPEN] Throws: Invalid argument if the Msgsize is too large")
    (assert-throws 'pmq-error "No such file or directory" '(pmq-open "/" T T (list O_CREAT) "0600") "[OPEN] Throws: No such file or directory when the only a slash '/' was given")

    (pmq-close Fd1)
    (pmq-close Fd2)
    (pmq-unlink "/___posixmq-tests1")
    (pmq-unlink "/___posixmq-tests2")

    (assert-throws 'pmq-error "Too many open files" '(for N (+ 1 *PMQ_os_msg_max) (let Fd (pmq-open (pack "/___posixmq-tests-z" N) T T (list O_CREAT) "0600") (pmq-close Fd))) "[OPEN] Throws: Too many open files when there's too many queues with default attributes")
    (chdir "/dev/mqueue/"
      (apply call (filter '((N) (pre? "___posixmq-tests-z" N)) (dir ".")) "rm" "-f") )
    (assert-throws 'pmq-error "No space left on device" '(for N (+ 1 *PMQ_os_queues_max) (let Fd (pmq-open (pack "/___posixmq-tests-x" N) T T (list O_CREAT O_EXCL) "0600" 4 20) (pmq-close Fd))) "[OPEN] Throws: No space left on device when there's too many queues")
    (chdir "/dev/mqueue/"
      (apply call (filter '((N) (pre? "___posixmq-tests-x" N)) (dir ".")) "rm" "-f") )
  ]

(de test-close ()
  (assert-kind-of 'Number (let Fd (pmq-open "/___posixmq-tests1" T T (list O_CREAT)) (pmq-close Fd)) "[CLOSE] Should validate 'close' returns a success code")
  (assert-throws 'pmq-error "Bad file descriptor" '(pmq-close 100000) "[CLOSE] Throws: Bad file descriptor when the FD is invalid")
  ]

(de test-unlink ()
  (assert-kind-of 'Number (let Fd (pmq-open "/___posixmq-tests1" T T (list O_CREAT)) (pmq-close Fd) (pmq-unlink "/___posixmq-tests1")) "[UNLINK] Should validate 'unlink' returns a success code")
  (assert-throws 'pmq-error "No such file or directory" '(pmq-unlink "/") "[UNLINK] Throws: No such file or directory when the queue name doesn't exist")
  (assert-throws 'pmq-error "File name too long" '(pmq-unlink (pack "/___posixmq" (need 255 "a"))) "[UNLINK] Throws: File name too long when the queue name is too long")
  ]

(de test-getattr ()
  (let Fd (pmq-open "/___posixmq-tests1" NIL T (list O_CREAT))
    (assert-equal (0 10 8192 0) (pmq-getattr Fd) "[GETATTR] Should validate 'getattr' has no messages on the queue")
    (pmq-send Fd "hello world" 5)
    (assert-equal (0 10 8192 1) (pmq-getattr Fd) "[GETATTR] Should validate 'getattr' has a new message on the queue")
    (assert-throws 'pmq-error "Bad file descriptor" '(pmq-getattr 100000) "[GETATTR] Throws: Bad file descriptor when the FD is invalid")

    (pmq-close Fd)
    (pmq-unlink "/___posixmq-tests1")
  ]

(de test-setattr ()
  (let Fd (pmq-open "/___posixmq-tests1" NIL T (list O_CREAT))
    (assert-equal (0 10 8192 0) (and (pmq-setattr Fd) (pmq-getattr Fd)) "[SETATTR] Should validate 'setattr' disables Nonblocking")
    (assert-equal (list O_NONBLOCK 10 8192 0) (and (pmq-setattr Fd T) (pmq-getattr Fd)) "[SETATTR] Should validate 'setattr' enables Nonblocking")
    (assert-equal (0 10 8192 0) (and (pmq-setattr Fd) (pmq-getattr Fd)) "[SETATTR] Should validate 'setattr' disables Nonblocking (again)")
    (assert-throws 'pmq-error "Bad file descriptor" '(pmq-setattr 100000 T) "[SETATTR] Throws: Bad file descriptor when the FD is invalid")

    (pmq-close Fd)
    (pmq-unlink "/___posixmq-tests1")
  ]

(de test-send ()
  (let Fd (pmq-open "/___posixmq-tests4" T T (list O_CREAT))
    (assert-kind-of 'Number (pmq-send Fd "hello world" 15) "[SEND] Should validate 'send' returns (number)")
    (assert-equal 0 (pmq-send Fd "testing 1" 5) "[SEND] Should validate 'send' returns (testing 1)")
    (assert-equal 0 (pmq-send Fd) "[SEND] Should validate 'send' returns 0 (empty message)")
    (assert-equal 0 (pmq-timedsend Fd "testing 2" 5 5) "[SEND] Should validate 'timed send' returns 0 (testing 2)")
    (pmq-send Fd "prio 1" 1)
    (pmq-send Fd "prio 10" 10)
    (assert-equal 6 (last (pmq-getattr Fd)) "[SEND] Should validate 'send' placed 6 messages on the queue")
    (assert-equal "hello world" (pmq-receive Fd) "[SEND] Should validate 'send' 1st message priority was 'hello world'")
    (assert-equal "prio 10" (pmq-receive Fd) "[SEND] Should validate 'send' 2nd message priority was 'prio 5'")
    (assert-equal "testing 1" (pmq-receive Fd) "[SEND] Should validate 'send' 3rd message priority was 'testing 1'")
    (assert-equal "testing 2" (pmq-receive Fd) "[SEND] Should validate 'send' 4th message priority was 'testing 2'")
    (assert-equal "prio 1" (pmq-receive Fd) "[SEND] Should validate 'send' 5th message priority was 'prio 1'")
    (assert-throws 'pmq-error "Bad file descriptor" '(pmq-send 100000) "[SEND] Throws: Bad file descriptor when the FD is invalid")
    (assert-throws 'pmq-error "Message too long" '(pmq-send Fd (pack (need (+ 1 *PMQ_msgsize) "a"))) "[SEND] Throws: Message too long when the message is too long")
    (pmq-setattr Fd T)
    (assert-throws 'pmq-error "Resource temporarily unavailable" '(for N (+ 1 *PMQ_maxmsg) (pmq-send Fd "a")) "[SEND] Throws: Resource temporarily unavailable when the queue is full in Nonblocking mode")
    (assert-throws 'pmq-error "Resource temporarily unavailable" '(pmq-timedsend Fd "testing 3" 5 5) "[SEND] Throws: Resource temporarily unavailable when a timed send is used in Nonblocking mode")
    (pmq-setattr Fd)
    (assert-throws 'pmq-error "Connection timed out" '(pmq-timedsend Fd "testing 3" 5) "[SEND] Throws: Connection timed out when a timed send blocks (default 0s)")
    (assert-throws 'pmq-error "Connection timed out" '(pmq-timedsend Fd "testing 3" 5 1) "[SEND] Throws: Connection timed out when a timed send blocks (argument 1s)")
    (assert-throws 'pmq-error "Invalid argument" '(pmq-timedsend Fd "testing 3" 5 -50000000000) "[SEND] Throws: Invalid argument when a timed send seconds count is invalid")

    (pmq-close Fd)
    (pmq-unlink "/___posixmq-tests4")
  ]

(de test-receive ()
  (let Fd (pmq-open "/___posixmq-tests5" T T (list O_CREAT))
    (pmq-send Fd "hello world" 15)
    (pmq-send Fd "testing 1" 5)
    (pmq-send Fd)
    (pmq-send Fd "testing 2" 0)
    (assert-kind-of 'String (pmq-receive Fd) "[RECEIVE] Should validate 'receive' returns (string)")
    (assert-equal "testing 1" (pmq-receive Fd) "[RECEIVE] Should validate 'receive' returns (testing 1)")
    (assert-nil (pmq-receive Fd) "[RECEIVE] Should validate 'receive' returns (empty string)")
    (assert-equal "testing 2" (pmq-timedreceive Fd 5) "[RECEIVE] Should validate 'timed receive' returns (testing 2)")
    (pmq-send Fd "prio 1" 1)
    (pmq-send Fd "prio 10" 10)
    (assert-equal 2 (last (pmq-getattr Fd)) "[RECEIVE] Should validate 'receive' placed 2 messages on the queue")
    (assert-equal "prio 10" (pmq-receive Fd) "[RECEIVE] Should validate 'receive' 1st message priority was 'prio 10'")
    (assert-equal "prio 1" (pmq-receive Fd) "[RECEIVE] Should validate 'receive' 2nd message priority was 'prio 1'")

    (assert-throws 'pmq-error "Bad file descriptor" '(pmq-receive 100000) "[RECEIVE] Throws: Bad file descriptor when the FD is invalid")
    (pmq-setattr Fd T)
    (assert-throws 'pmq-error "Resource temporarily unavailable" '(pmq-receive Fd) "[RECEIVE] Throws: Resource temporarily unavailable when the queue is empty in Nonblocking mode")
    (assert-throws 'pmq-error "Resource temporarily unavailable" '(pmq-timedreceive Fd 5) "[RECEIVE] Throws: Resource temporarily unavailable when a timed send is used in Nonblocking mode")
    (pmq-setattr Fd)
    (assert-throws 'pmq-error "Connection timed out" '(pmq-timedreceive Fd) "[RECEIVE] Throws: Connection timed out when a timed receive blocks (default 0s)")
    (assert-throws 'pmq-error "Connection timed out" '(pmq-timedreceive Fd 1) "[RECEIVE] Throws: Connection timed out when a timed receive blocks (argument 1s)")
    (assert-throws 'pmq-error "Invalid argument" '(pmq-timedreceive Fd -50000000000) "[RECEIVE] Throws: Invalid argument when a timed receive seconds count is invalid")

    (pmq-close Fd)
    (pmq-unlink "/___posixmq-tests5")
  ]

(execute
  '(test-constants)
  '(test-types)
  '(test-open)
  '(test-close)
  '(test-unlink)
  '(test-getattr)
  '(test-setattr)
  '(test-send)
  '(test-receive)
  ]
