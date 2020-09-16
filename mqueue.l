# picolisp-posixmq - https://github.com/aw/picolisp-posixmq
#
# Library for working with POSIX Message Queues in PicoLisp (64-bit only)
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

###
# VARIABLES
###

(setq
  *Librt              "librt.so"
  *PMQ_verbose        T
  *PMQ_maxmsg         (in "/proc/sys/fs/mqueue/msg_default" (read))
  *PMQ_msgsize        (in "/proc/sys/fs/mqueue/msgsize_default" (read))
  *PMQ_os_msg_max     (in "/proc/sys/fs/mqueue/msg_max" (read))
  *PMQ_os_msgsize_max (in "/proc/sys/fs/mqueue/msgsize_max" (read))
  *PMQ_os_queues_max  (in "/proc/sys/fs/mqueue/queues_max" (read))
  O_CLOEXEC           (hex "80000") )   # Linux
  #O_CLOEXEC           (hex "100000") ) # FreeBSD
  #O_CLOEXEC           (hex "10000") )  # OpenBSD

###
# HELPERS
###

(de pmq-get-sysdef (N)
  (set (any N) (in '("@src64/sysdefs") (from N) (read) ]

(de pmq-set-constants ()
  (if (> (version T) (21)) # test for pil21 VS pil64
      (sysdefs "Posix Message Queues" (pack "sysdefs." (lowc *OS)))
      (mapcar pmq-get-sysdef '("O_RDONLY" "O_WRONLY" "O_RDWR" "O_CREAT" "O_EXCL" "O_NONBLOCK") ]

(de pmq-output @
  (when *PMQ_verbose (prinl "[" (dat$ (date) "-") "T" (tim$ (time) T) "] " (rest) ]

(de pmq-error (Code Fun)
  (let Msg (native "@" "strerror" 'S Code)
    (setq *Msg (cons Code Msg))
    (pmq-output "Error '" Code "' in '(" Fun ")' - " Msg)
    (throw 'pmq-error Msg) ]

(de pmq-return (Code Res . @)
  (if (lt0 Code)
      (pmq-error (errno) (car (up 2)))
      (pmq-output (rest))
      Res ]

# defaults to O_RDONLY
(de pmq-get-type (Read Write)
  (if Write
      (if Read
          O_RDWR
          O_WRONLY )
      O_RDONLY ) )

(de pmq-mem (Size)
  (native "@" "malloc" 'N Size) )

(de pmq-free (Buf)
  (native "@" "free" NIL Buf) )

###
# MQUEUE
###

(de pmq-open (Name Read Write Flags Mode Maxmsg Msgsize)
  (default Flags)
  (default Mode "0600")
  (default Maxmsg *PMQ_maxmsg)
  (default Msgsize *PMQ_msgsize)

  (let (Type    (pmq-get-type Read Write)
        Mem     (pmq-mem 32)
        Attr    (struct Mem 'N (0 . 8) (cons Maxmsg 8) (cons Msgsize 8) (0 . 8))
        Res     (native `*Librt "mq_open" 'I Name (apply | Flags Type) (oct Mode) Mem) )

    (pmq-free Mem)
    (pmq-return Res Res "Opened queue: Name='" Name "', FD=" Res) ]

(de pmq-close (Fd)
  (let Res (native `*Librt "mq_close" 'I Fd)
    (pmq-return Res Res "Closed queue: FD=" Fd) ]

(de pmq-unlink (Name)
  (let Res (native `*Librt "mq_unlink" 'I Name)
    (pmq-return Res Res "Unlinked queue: Name='" Name "'") ]

(de pmq-getattr (Fd)
  (let (Attr    NIL
        Res     (native `*Librt "mq_getattr" 'I Fd (list 'Attr (64 N . 4) 0)) )

    (pmq-return Res Attr "Get attributes: Flags=" (car Attr) ", Maxmsg=" (; Attr 2) ", Msgsize=" (; Attr 3) ", Curmsgs=" (last Attr) ", FD=" Fd) ]

(de pmq-setattr (Fd Nonblock)
  (let (Mem     (pmq-mem 32)
        Attr    (struct Mem 'N (cons (if Nonblock O_NONBLOCK 0) 8 . 0))
        Res     (native `*Librt "mq_setattr" 'I Fd Mem 0) )

    (pmq-free Mem)
    (pmq-return Res Attr "Set attributes: Nonblocking=" (if Nonblock "yes" "no") ", FD=" Fd) ]

(de pmq-send (Fd Msg Prio)
  (default Prio 0)

  (let Res (native `*Librt "mq_send" 'I Fd Msg (+ (length Msg) 1) Prio)
    (pmq-return Res Res "Send: String='" Msg "', FD=" Fd) ]

(de pmq-timedsend (Fd Msg Prio Seconds)
  (default Prio 0)
  (default Seconds 0)

  (let (Mem     (pmq-mem 16)
        Timeout (+ Seconds (native "@" "time" 'N 0))
        Time    (struct Mem 'N (cons Timeout 8) (0 . 8))
        Res     (native `*Librt "mq_timedsend" 'I Fd Msg (+ (length Msg) 1) Prio Mem) )

    (pmq-free Mem)
    (pmq-return Res Res "Timed send: String='" Msg "', FD=" Fd) ]

(de pmq-receive (Fd)
  (let (Size    (caddr (pmq-getattr Fd))
        Msg     (pmq-mem Size)
        Res     (native `*Librt "mq_receive" 'I Fd Msg Size 0)
        Str     (native "@" "strdup" 'S Msg) )

    (pmq-free Msg)
    (pmq-return Res Str "Receive: String='" Str "' (" Res " Bytes), FD=" Fd) ]

(de pmq-timedreceive (Fd Seconds)
  (default Seconds 0)

  (let (Size    (caddr (pmq-getattr Fd))
        Msg     (pmq-mem Size)
        Mem     (pmq-mem 16)
        Timeout (+ Seconds (native "@" "time" 'N 0))
        Time    (struct Mem 'N (cons Timeout 8) (0 . 8))
        Res     (native `*Librt "mq_timedreceive" 'I Fd Msg Size 0 Mem)
        Str     (native "@" "strdup" 'S Msg) )

    (pmq-free Msg)
    (pmq-free Mem)

    (pmq-return Res Str "Timed receive: String='" Str "' (" Res " Bytes), FD=" Fd) ]

###
# INITIALIZE
###

(pmq-set-constants)
