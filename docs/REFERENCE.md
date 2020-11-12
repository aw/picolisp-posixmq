# POSIX Message Queues: Reference

This document provides technical information on the internals of this library.

## Menu

  1. [OS settings and defaults](#1-os-settings-and-defaults)
  2. [Variables and constants](#2-variables-and-constants)
  3. [Public functions and arguments](#3-public-functions)
  4. [Error handling](#4-error-handling)

| Functions | Description |
| ---- | ---- |
| [(pmq-open)](#pmq-open) name [flags mode maxmsg msgsize] | Create a new queue, or open an existing one |
| [(pmq-close)](#pmq-close) filedescriptor | Close a queue |
| [(pmq-unlink)](#pmq-unlink) name | Remove a queue |
| [(pmq-getattr)](#pmq-getattr) filedescriptor | Get the attributes of an opened queue |
| [(pmq-setattr)](#pmq-setattr) filedescriptor [nonblocking] | Set the non-blocking attribute of an opened queue |
| [(pmq-send)](#pmq-send) filedescriptor [message priority seconds] | Send a message to a queue with a<br/>prority level and a timeout |
| [(pmq-receive)](#pmq-receive) filedescriptor [seconds] | Receive a message from a queue with a timeout |
| [(pmq-getsettings)](#pmq-getsettings) [setting] | Get the OS setting(s) from Procfs |

---

# 1. OS settings and defaults

On Linux, default queue limits are quite low, and should be changed to match your application's needs.

Changing these values **require root** as they must modify the kernel runtime parameters via `sysctl` or `/proc`.

The current value of of these settings can be obtained with [(pmq-getsettings)](#pmq-getsettings).

## New queue defaults (create)

These **two (2)** values can be provided as arguments to [(pmq-open)](#pmq-open), otherwise the default values below are used.

**Maximum number of messages stored in a queue**

  - Default: `10`
  - Hard limit: see `/proc/sys/fs/mqueue/msg_max`
  - Procfs: `/proc/sys/fs/mqueue/msg_default`
  - Sysctl: `fs.mqueue.msg_default`

**Maximum size of each message stored in a queue**

  - Default: `8192 Bytes (8KiB)`
  - Hard limit: see `/proc/sys/fs/mqueue/msgsize_max`
  - Procfs: `/proc/sys/fs/mqueue/msgsize_default`
  - Sysctl: `fs.mqueue.msgsize_default`

From the defaults above, it is possible to store at most `10` messages of `8192 Bytes` each per queue with at most `256` queues (see [Queue limits](#queue-limits) below).

## Queue limits

These values can increase or decrease the limits of arguments supplied to [(pmq-open)](#pmq-open).

**Maximum number of messages stored in a queue**

  - Default: `10`
  - Hard limit: `65536`
  - Procfs: `/proc/sys/fs/mqueue/msg_max`
  - Sysctl: `fs.mqueue.msg_max`

**Maximum size of each message stored in a queue**

  - Default: `8192 Bytes (8KiB)`
  - Hard limit: `16777216 Bytes (16MiB)`
  - Procfs: `/proc/sys/fs/mqueue/msgsize_max`
  - Sysctl: `fs.mqueue.msgsize_max`

**Maximum number of queues which can be created**

  - Default: `256`
  - Hard limit: `none`
  - Procfs: `/proc/sys/fs/mqueue/queues_max`
  - Sysctl: `fs.mqueue.queues_max`

From the hard limits above, it is possible to store at most `65536` messages of `16777216 Bytes` each per queue with an unlimited number of queues (limited by memory, of course).

Please read the [HOWTO](HOWTO.md) to learn how to change these settings for your application.

More information on queue settings can be found in the [mq_overview(7)](https://man7.org/linux/man-pages/man7/mq_overview.7.html) man page.

---

# 2. Variables and constants

This library defines a few global variables and constants.

## Variables

These global variables can be changed after loading the library:

***Librt**

Maps to the shared library for using POSIX message queues.

  - Default: `librt.so`

***PMQ_verbose**

Enable or disable verbose output.

  - Default: `T` (enabled)

## Constants

These OS constants are the **Flags** which must be supplied to the [(pmq-open)](#pmq-open) function.

They should be changed if you're running a different operating system such as FreeBSD. They are hardcoded in `sysdefs.linux` and initialized when loading the library.

**O_RDONLY**

Open the queue in read-only mode, to receive messages only.

  - Value: `0`

**O_WRONLY**

Open the queue in write-only mode, to send messages only.

  - Value: `1`

**O_RDWR**

Open the queue in read+write mode, to both send and receive messages.

  - Value: `2`

**O_CREAT**

Create the message queue if it does not exist.

  - Value: `64`

**O_EXCL**

If **O_CREAT** is specified and a queue with the given name already exists, then opening the queue will fail with an error.

  - Value: `128`

**O_NONBLOCK**

Open the queue in nonblocking mode, so sending and receiving a message will return immediately with an error instead of blocking.

  - Value: `2048`

**O_CLOEXEC**

Enable the close-on-exec flag for the message queue.

  - Value: `524288`

More information on flag values can be found in the [mq_open(3)](https://man7.org/linux/man-pages/man3/mq_open.3.html) man page.

---

# 3. Public functions and arguments

This library prefixes private `local` functions with an `underscore`, ex: `_pmq-*`. Global `public` functions are prefixed without an underscore, ex: `pmq-*`.

This section will describe the public functions only, because private functions should not be called directly.

## (pmq-open)

Create a new queue, or open an existing one.

```picolisp
(pmq-open name flags mode maxmsg msgsize)
```

#### Returns

**filedescriptor** `number`, or throws an error with jump label `'pmq-error`

A file descriptor which must be passed to almost every other function. Store this value in a variable and remember to call [(pmq-close)](#pmq-close) when you're finished working with the queue.

#### Arguments

**name** `string` (required)

The name of the queue, which must begin with `/` and must be followed by valid UTF-8 characters.

  - Example: `"/myqueue"`

**flags** `list`

Optional flag constants for creating or opening the queue.

  - Default: `(list O_RDONLY)`
  - Options: `O_RDONLY`, `O_WRONLY`, `O_RDWR`, `O_CREAT`, `O_CLOEXEC`, `O_EXCL`, `O_NONBLOCK`
  - Example: `(list O_RDWR O_CREAT O_NONBLOCK)`

The `O_RDONLY`, `O_WRONLY`, `O_RDWR` flags are mutually exclusive, so only one of those should be used when opening or creating a queue.

**mode** `string`

The octal mode (permissions) of the queue on the filesystem. Although it's an octal value, it must be passed as a `string`, since the library will handle converting it to the proper format.

  - Default: `"0600"` (file permissions `-rw-------`)
  - Example: `"0640"` (file permissions `-rw-r-----`)

**maxmsg** `number`

The maximum number of messages in a queue. This number is limited by the value returned from `(pmq-getsettings "msg_max")`.

  - Default: `10`
  - Example: `5`

**msgsize** `number`

The maximum size of a message in a queue. This number is limited by the value returned from `(pmq-getsettings "msgsize_max")`.

  - Default: `8192`
  - Example: `4096`

#### Usage examples

Create a non-blocking queue in read+write mode:

```picolisp
(pmq-open "/myqueue" (list O_RDWR O_CREAT O_NONBLOCK))
-> 3
```

Open a blocking queue in read-only mode:

```picolisp
(pmq-open "/myqueue")
-> 3
```

Open a queue in write-only mode with permissions 0644:

```picolisp
(pmq-open "/myqueue" (list O_WRONLY) "0644")
-> 3
```

Catch an error trying to open a queue in an invalid name:

```picolisp
(catch 'pmq-error
  (pmq-open "invalidname") )
-> "Invalid argument"
```

---

## (pmq-close)

Close a queue.

```picolisp
(pmq-close filedescriptor)
```

#### Returns

**success code** `0`, or throws an error with jump label `'pmq-error`

#### Arguments

**filedescriptor** `number` (required)

The file descriptor which was returned by [(pmq-open)](#pmq-open).

  - Example: `(pmq-close 3)`

#### Usage examples

Close a previously opened queue with file descriptor `3`:

```picolisp
(pmq-close 3)
-> 0
```

Catch an error trying to close an invalid file descriptor:

```picolisp
(catch 'pmq-error
  (pmq-close 42) )
-> "Bad file descriptor"
```

---

## (pmq-unlink)

Remove a queue.

```picolisp
(pmq-unlink name)
```

#### Returns

**success code** `0`, or throws an error with jump label `'pmq-error`

#### Arguments

**name** `string` (required)

The name of the queue, which must begin with `/` and must be followed by valid UTF-8 characters.

  - Example: `"/myqueue"`

#### Usage examples

Remove an existing queue with name `"/myqueue"`:

```picolisp
(pmq-unlink "/myqueue")
-> 0
```

Catch an error trying to remove a queue that doesn't exist:

```picolisp
(catch 'pmq-error
  (pmq-unlink "/noqueue") )
-> "No such file or directory"
```

---

## (pmq-getattr)

Get the attributes (settings) of an opened queue.

```picolisp
(pmq-getattr filedescriptor)
```

#### Returns

**queue attributes** `list`, or throws an error with jump label `'pmq-error`

The list contains 4 values in the following order:

  1. Flags: `0` or `O_NONBLOCK`
  2. The maximum number of messages in the queue
  3. The maximum size of a message in the queue
  4. The number of messages currently in the queue

#### Arguments

**filedescriptor** `number` (required)

The file descriptor which was returned by [(pmq-open)](#pmq-open).

  - Example: `(pmq-getattr 3)`

#### Usage examples

Get the attributes of a previously opened non-blocking queue with file descriptor `3`, and `2` messages waiting in the queue:

```picolisp
(pmq-getattr 3)
-> (2048 10 8192 2)
```

Catch an error trying to get the attributes of an invalid file descriptor:

```picolisp
(catch 'pmq-error
  (pmq-getattr 42) )
-> "Bad file descriptor"
```

---

## (pmq-setattr)

Set the non-blocking attribute of an opened queue.

```picolisp
(pmq-setattr filedescriptor nonblocking)
```

#### Returns

**success code** `0`, or throws an error with jump label `'pmq-error`

#### Arguments

**filedescriptor** `number` (required)

The file descriptor which was returned by [(pmq-open)](#pmq-open).

  - Example: `(pmq-setattr 3)`

**nonblocking** `flag`

To enable non-blocking mode on the queue, set this flag to `T`.

  - Default: `NIL`
  - Options: `T`, `NIL`
  - Example: `(pmq-setattr 3 T)`


#### Usage examples

Get the queue attributes, set the non-blocking attribute, then get the queue attributes once more:

```picolisp
(pmq-getattr 3)
-> (0 10 8192 0)
(pmq-setattr 3 T)
-> 0
(pmq-getattr 3)
-> (2048 10 8192 0)
```

Catch an error trying to set the non-blocking attribute of an invalid file descriptor:

```picolisp
(catch 'pmq-error
  (pmq-setattr 42 T) )
-> "Bad file descriptor"
```

---

## (pmq-send)

Send a message to a queue with a prority level and a timeout.

```picolisp
(pmq-send filedescriptor message priority seconds)
```

This function will block for `<seconds>` (or forever) when trying to send a message to a **full queue**, unless the queue has the `non-blocking` attribute. In that case it won't block, and will return an error right away if the queue is full.

This function will also unblock once a message is removed from the queue.

#### Returns

**success code** `0`, or throws an error with jump label `'pmq-error`

#### Arguments

**filedescriptor** `number` (required)

The file descriptor which was returned by [(pmq-open)](#pmq-open).

  - Example: `(pmq-send 3)`

**message** `string`

  - Default: `NIL`
  - Options: `NIL` or `string`
  - Example: `"Hello World"`

An empty string `""` or `NIL` will send a [null byte](https://en.wikipedia.org/wiki/Null_byte) to the message queue.

**priority** `number`

The highest priority level of a message sent to a queue. The lower the number, the lower the priority.

  - Default: `0`
  - Options: `NIL`, or `0` to `32767`
  - Example: `10`

**seconds** `number`

The number of seconds to block on a queue before returning with an error.

  - Default: `NIL` (no timeout)
  - Example: `10`

#### Usage examples

Send a message to a non-blocking queue with priority `5`:

```picolisp
(pmq-send 3 "Hello" 5)
-> 0
```

Send a message to a non-blocking queue with priority `20`:

```picolisp
(pmq-send 3 "World" 20)
-> 0
```

Send a message to a blocking queue with priority `20` and timeout of `10` seconds:

```picolisp
(catch 'pmq-error
  (pmq-send 3 "Block 10s" 20 10)
-> "Connection timed out"
```

---

## (pmq-receive)

Receive a message from a queue with a timeout.

```picolisp
(pmq-receive filedescriptor seconds)
```

This function will block for `<seconds>` (or forever) when trying to receive a message from an **empty queue**, unless the queue has the `non-blocking` attribute. In that case it won't block, and will return an error right away if the queue is empty.

This function will also unblock once a message is added to the queue.

#### Returns

**success code** `0`, or throws an error with jump label `'pmq-error`

#### Arguments

**filedescriptor** `number` (required)

The file descriptor which was returned by [(pmq-open)](#pmq-open).

  - Example: `(pmq-receive 3)`

**seconds** `number`

The number of seconds to block on a queue before returning with an error.

  - Default: `NIL` (no timeout)
  - Example: `10`

#### Usage examples

Receive a message to a non-blocking queue:

```picolisp
(pmq-receive 3)
-> 0
```

Receive a message from a blocking queue with timeout of `10` seconds:

```picolisp
(catch 'pmq-error
  (pmq-receive 3 10)
-> "Connection timed out"
```

---

## (pmq-getsettings)

Get the OS setting(s) from Procfs.

```picolisp
(pmq-getsettings setting)
```

This function will fetch the _POSIX Message Queues_ settings from `/proc`, which can be used to keep track of limits enforced by the system.

#### Returns

**cons pair(s)** `list`, with the setting name in the `(car)` and value in the `(cdr)`

#### Arguments

**setting** `string`

The OS setting you want to get from Procfs.

  - Default: `T` (all settings)
  - Options: `T`, `NIL`, `string`
  - Example: `(pmq-getsettings "msg_default")`

#### Usage examples

Get one specific OS setting:

```picolisp
(pmq-getsettings "msg_default")
-> ("msg_default" . 10)
```

Get all OS settings:

```picolisp
(pmq-getsettings)
-> (("msg_default" . 10) ("msgsize_default" . 8192) ("msg_max" . 10) ("msgsize_max" . 8192) ("queues_max" . 256))
```

---

# 4. Error handling

Almost every public function in this library can throw an error using `(throw)` with the jump label `'pmq-error`.

Use `(catch 'pmq-error .. (pmq-..)` to catch errors and avoid crashing your application.

When an error is thrown, the `(catch)` will return the error message as a `string`, and it will set the global variable `*Msg` with a cons pair containing the error code and error message.

#### Error example

This example output tries to receive a message from a non-blocking queue which doesn't have any messages:

```picolisp
: (catch 'pmq-error
    (pmq-receive 3) )
[2020-09-23T00:40:25] Get attributes: Flags=2048, Maxmsg=10, Msgsize=8192, Curmsgs=0, FD=3
[2020-09-23T00:40:25] Error '11' in '(pmq-receive)' - Resource temporarily unavailable
-> "Resource temporarily unavailable"
: *Msg
-> (11 . "Resource temporarily unavailable")
```

---

Now that you've read the entire technical reference, feel free to read the other documents below:

  * [TUTORIALS](docs/TUTORIALS.md): some guides to **get started** using this library
  * [HOWTO](HOWTO.md): a set of recipes for performing more advanced tasks with this library
  * [EXPLAIN](EXPLAIN.md): an explanation of some key concepts, including how this library works

# License

This documentation is Copyright (c) 2020~ Alexander Williams, On-Prem <license@on-premises.com>, and licensed under the [Creative Commons (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/) license.
