# POSIX Message Queues: Explain

This document provides an explanation of some key concepts, including how this library works.

We'll begin by explaining the overall idea behind this library, why it exists, and what it can be used for. Then we'll go deeper into how the code is structured, along with a peek behind the complicated bits. Finally we'll wrap up with an overview of alternatives to _POSIX Message Queues_.

  1. [POSIX Message Queues in 2020](#posix-messages-queues-in-2020)
  2. [The code behind the code](#the-code-behind-the-code)
  3. [Interesting alternatives](#interesting-alternatives)

---

# 1. POSIX Messages Queues in 2020

Who uses [POSIX Message Queues](https://man7.org/linux/man-pages/man7/mq_overview.7.html) (_PMQs_) in 2020? Probably a least a few people, but most won't post about it on _HN_. When you think about it, the same could be said about `Lisp`.

There's a reason _PMQs_ are still around. Just like `Lisp` and `C`, they do their job very well, and then get out of the way. _PMQs_ greatly reduce the cognitive load required to get one simple job done:

**To have multiple processes communicate together asynchronously**

### Why use a PMQ?

The concept behind a [message queue](https://en.wikipedia.org/wiki/Message_queue) is an old one, and won't go away anytime soon. You might want process **A** to send one or more messages to **B**, and you might want **B** to read those messages asynchronously. In fact, you might even want **C** to read those messages if **B** is taking a nap. _PMQs_ help you do that.

This library was written to solve the specific problem above, without the overhead of downloading, compiling, installing, and _figuring out_ a new application with complex jargon, patterns, and concepts.

This library was written to be embedded in larger [PicoLisp](https://picolisp.com) applications, so it is licensed freely as well.

This library was written as glue to _POSIX Message Queues_ on a `Linux` operating system, with the goal to abstract out the slightly more complicated parts of the native C interface.

### What else can it do?

Well since you asked, new tools can be built on top of this library, such as a TCP Server (see the [HOWTO](HOWTO.md) for that), and even a [Publish/Subscribe](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) system with security, authentication, persistence, and all that fun stuff.

At the core, this library doesn't do much except send and receive messages asynchronously. It is designed to be reliable and bug-free, and ships with 100% test coverage.

### Why aren't PMQs popular?

Fashion and bad defaults are likely to be blamed.

_Fashion_ because it's much more fun to use a tool that does everything in one package, guarantees 100000 ops/sec, zero latency, and ultimate scalability with cloud integrations.

_Bad defaults_ because the Linux Kernel ships _PMQs_ with extremely limited default settings, requiring the root user to increase those defaults for production use. It's an easy work-around (a simple `sysctl` or `/proc` change), but that makes it difficult to adopt for people who don't fully control their operating system.

### OK now what?

If you're already running Linux, the good news is you already have everything you need to use _PMQs_. In fact, you don't even need this library.

However if you're building PicoLisp applications, then you'll be better off [cloning this repo](https://github.com/aw/picolisp-posixmq), running `make check`, and then including `mqueue.l` in your application.

---

# 2. The code behind the code

---

# Notes

The _POSIX Message Queues_ implementations is Linux is slightly less efficient and severely limited compared to networked message queues such as [ZeroMQ](https://zeromq.org/), [Nanomsg](https://nanomsg.org/), [AMQP](https://www.amqp.org/), and [MQTT](https://mqtt.org/). The advantage of _POSIX Message Queues_ is there are **no additional dependencies** to use them, and the only security/update concerns are directly tied to the kernel of your OS. For specific use cases, this can be much better than trying to adopt a new external dependency.

On Linux, certain OS settings must be tweaked to increase limits, such as the maximum size of a message (8KB), maximum number of queues (256), and maximum number of queued messages (10). This **must be done by root**, and is described in detail in the [HOWTO](docs/HOWTO.md) documentation.

---

Now that you understand how all this works, feel free to read the other documents below:

  * [TUTORIALS](TUTORIALS.md): some guides **for beginners** to get started using this library
  * [HOWTO](HOWTO.md): a set of recipes for performing more advanced tasks with this library
  * [REFERENCE](REFERENCE.md): technical information on the internals of this library

# License

This documentation is Copyright (c) 2020~ Alexander Williams, On-Prem <license@on-premises.com>, and licensed under the [Creative Commons (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/) license.
