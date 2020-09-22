# picolisp-posixmq - https://github.com/aw/picolisp-posixmq
#
# POSIX Message Queues library for PicoLisp (64-bit only)
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

###
# VARIABLES
###

(setq
  *Librt              "librt.so"
  *PMQ_verbose        T )

###
# HELPERS
###

# source: pil21.tgz 'lib.l'
(de _pmq-sysdefs ("Sym" "Alt")
 (in "Alt"
    (if (from (pack "\n[" "Sym" "]\n"))
       (while (and (skip) (<> "[" @))
          (def (read) (read)) )
       (quit "No sysdefs" "Sym") ) ) )

(de _pmq-set-constants ()
  (_pmq-sysdefs "Posix Message Queues" (pack "sysdefs." (lowc *OS))) )

(de _pmq-output @
  (when *PMQ_verbose (prinl "[" (dat$ (date) "-") "T" (tim$ (time) T) "] " (rest) ]

(de _pmq-error (Code Fun)
  (let Msg (native "@" "strerror" 'S Code)
    (setq *Msg (cons Code Msg))
    (_pmq-output "Error '" Code "' in '(" Fun ")' - " Msg)
    (throw 'pmq-error Msg) ]

(de _pmq-return (Code Res . @)
  (if (lt0 Code)
      (_pmq-error (errno) (car (up 2)))
      (_pmq-output (rest))
      Res ]

(de _pmq-get-timeout (Seconds)
  (let (Mem     (_pmq-mem 16)
        Timeout (+ Seconds (native "@" "time" 'N 0))
        Time    (struct Mem 'N (cons Timeout 8) (0 . 8)) )

    Mem ]

(de _pmq-get-type (Read Write)
  (if Write
      (if Read
          O_RDWR
          O_WRONLY )
      O_RDONLY ) ) # default

(de _pmq-mem (Size)
  (native "@" "malloc" 'N Size) )

(de _pmq-free (Buf)
  (native "@" "free" NIL Buf) )

###
# MQUEUE
###

(de pmq-open (Name Read Write Flags Mode Maxmsg Msgsize)
  (default Flags)
  (default Mode "0600")
  (default Maxmsg (cdr (pmq-getsettings "msg_default")))
  (default Msgsize (cdr (pmq-getsettings "msgsize_default")))

  (let (Type    (_pmq-get-type Read Write)
        Mem     (_pmq-mem 32)
        Attr    (struct Mem 'N (0 . 8) (cons Maxmsg 8) (cons Msgsize 8) (0 . 8))
        Res     (native `*Librt "mq_open" 'I Name (apply | Flags Type) (oct Mode) Mem) )

    (_pmq-free Mem)
    (_pmq-return Res Res "Opened queue: Name='" Name "', FD=" Res) ]

(de pmq-close (Fd)
  (let Res (native `*Librt "mq_close" 'I Fd)
    (_pmq-return Res Res "Closed queue: FD=" Fd) ]

(de pmq-unlink (Name)
  (let Res (native `*Librt "mq_unlink" 'I Name)
    (_pmq-return Res Res "Unlinked queue: Name='" Name "'") ]

(de pmq-getattr (Fd)
  (use Attr
    (let Res (native `*Librt "mq_getattr" 'I Fd (list 'Attr (64 N . 4) 0))
      (_pmq-return Res Attr "Get attributes: Flags=" (car Attr) ", Maxmsg=" (; Attr 2) ", Msgsize=" (; Attr 3) ", Curmsgs=" (last Attr) ", FD=" Fd) ]

(de pmq-setattr (Fd Nonblock)
  (let (Mem     (_pmq-mem 32)
        Attr    (struct Mem 'N (cons (if Nonblock O_NONBLOCK 0) 8 . 0))
        Res     (native `*Librt "mq_setattr" 'I Fd Mem 0) )

    (_pmq-free Mem)
    (_pmq-return Res Attr "Set attributes: Nonblocking=" (if Nonblock "yes" "no") ", FD=" Fd) ]

(de pmq-send (Fd Msg Prio)
  (default Prio 0)

  (let Res (native `*Librt "mq_send" 'I Fd Msg (+ (size Msg) 1) Prio)
    (_pmq-return Res Res "Send: String='" Msg "', Priority=" Prio ", FD=" Fd) ]

(de pmq-timedsend (Fd Msg Prio Seconds)
  (default Prio 0)
  (default Seconds 0)

  (let (Time    (_pmq-get-timeout Seconds)
        Res     (native `*Librt "mq_timedsend" 'I Fd Msg (+ (size Msg) 1) Prio Time) )

    (_pmq-free Time)
    (_pmq-return Res Res "Timed send: String='" Msg "', Priority=" Prio ", FD=" Fd) ]

(de pmq-receive (Fd)
  (let (Size    (caddr (pmq-getattr Fd))
        Msg     (_pmq-mem Size)
        Buf     (struct Msg 'S (0 . Size))
        Res     (native `*Librt "mq_receive" 'I Fd Msg Size 0)
        Str     (struct Msg 'S) )

    (_pmq-free Msg)
    (_pmq-return Res Str "Receive: String='" Str "' (" Res " Bytes), FD=" Fd) ]

(de pmq-timedreceive (Fd Seconds)
  (default Seconds 0)

  (let (Size    (caddr (pmq-getattr Fd))
        Msg     (_pmq-mem Size)
        Buf     (struct Msg 'S (0 . Size))
        Time    (_pmq-get-timeout Seconds)
        Res     (native `*Librt "mq_timedreceive" 'I Fd Msg Size 0 Time)
        Str     (struct Msg 'S) )

    (_pmq-free Msg)
    (_pmq-free Time)

    (_pmq-return Res Str "Timed receive: String='" Str "' (" Res " Bytes), FD=" Fd) ]

(de pmq-getsettings (Setting)
  (case Setting
    ["msg_default"        (cons @ (in "/proc/sys/fs/mqueue/msg_default" (read) ]
    ["msgsize_default"    (cons @ (in "/proc/sys/fs/mqueue/msgsize_default" (read) ]
    ["msg_max"            (cons @ (in "/proc/sys/fs/mqueue/msg_max" (read) ]
    ["msgsize_max"        (cons @ (in "/proc/sys/fs/mqueue/msgsize_max" (read) ]
    ["queues_max"         (cons @ (in "/proc/sys/fs/mqueue/queues_max" (read) ]
    [T  (list
          (cons "msg_default"     (in "/proc/sys/fs/mqueue/msg_default" (read)))
          (cons "msgsize_default" (in "/proc/sys/fs/mqueue/msgsize_default" (read)))
          (cons "msg_max"         (in "/proc/sys/fs/mqueue/msg_max" (read)))
          (cons "msgsize_max"     (in "/proc/sys/fs/mqueue/msgsize_max" (read)))
          (cons "queues_max"      (in "/proc/sys/fs/mqueue/queues_max" (read))) ] ]

###
# INITIALIZE
###

(_pmq-set-constants)
