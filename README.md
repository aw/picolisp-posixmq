# POSIX Message Queues library for PicoLisp (64-bit only)

_[POSIX Message Queues](https://man7.org/linux/man-pages/man7/mq_overview.7.html)_ provide a dependency-free mechanism for processes to exchange data in the form of messages.

This library makes it simple to embed support for _POSIX Message Queues_ in [PicoLisp](https://picolisp.com) applications running on Linux.

  1. [Requirements](#requirements)
  2. [Getting Started](#getting-started)
  3. [Quick Start](#quick-start)
  4. [Documentation](#documentation)
  5. [Testing](#testing)
  6. [Contributing](#contributing)
  7. [Changelog](#changelog)
  8. [License](#license)

# Requirements

  * PicoLisp **64-bit** `v17.12` to `v20.7.16`, or `pil21`
  * Linux with kernel `v3.5+`
  * Kernel *POSIX Message Queues* support
  * POSIX Realtime Extensions library (**librt.so**)

# Getting Started

The first step is to run the unit tests: `make check`

If those fail, jump to the [TUTORIALS](docs/TUTORIALS.md) section to perform the initial setup and system check.

If all works well, then your system is ready to use this library.

# Quick Start

The code below illustrates how to use the queue for sending and receiving a message.

#### Example Code

```picolisp
(load "mqueue.l")                               # load the library
(let Fd (pmq-open "/myQ" (list O_RDWR O_CREAT)) # create a read/write queue named "/myQ"
  (pmq-send Fd "Hello World")                   # send the message "Hello World"
  (pmq-receive Fd)                              # receive the message
  (pmq-close Fd)                                # close the queue
  (pmq-unlink "/myQ") )                         # remove the queue
```

#### Example Output

**Note:** Verbose output is enabled by default and can be disabled with `(off *PMQ_verbose)`.

```none
[2020-09-17T03:37:15] Opened queue: Name='/myqueue', FD=3
[2020-09-17T03:37:15] Send: String='Hello World', Priority=0, FD=3
[2020-09-17T03:37:15] Get attributes: Flags=0, Maxmsg=10, Msgsize=8192, Curmsgs=1, FD=3
[2020-09-17T03:37:15] Receive: String='Hello World' (12 Bytes), FD=3
[2020-09-17T03:37:15] Closed queue: FD=3
[2020-09-17T03:37:15] Unlinked queue: Name='/myqueue'
-> 0
```

# Documentation

Additional usage and reference documentation can be found in [docs/](docs/)

  * [TUTORIALS](docs/TUTORIALS.md): some guides to **get started** using this library
  * [HOWTO](docs/HOWTO.md): a set of recipes for performing more advanced tasks with this library
  * [EXPLAIN](docs/EXPLAIN.md): an explanation of some key concepts, including how this library works
  * [REFERENCE](docs/REFERENCE.md): technical information on the internals of this library

# Testing

This library comes with a large suite of [unit and integration tests](https://github.com/aw/picolisp-unit). To run the tests, type:

    make check

# Contributing

  * For bugs, issues, or feature requests, please [create an issue](https://github.com/aw/picolisp-posixmq/issues/new).

# Changelog

[Changelog](CHANGELOG.md)

# License

[MIT License](LICENSE)

Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>
