# POSIX Message Queues: Tutorials

This document provides some guides **for beginners** to get started using this library.

In these tutorials, you will learn how to get up and running, as well as how to perform basic tasks with this library.

The examples are not very practical for daily use, but should give some good insight into how this library can be used.

Once you've graduated from the tutorials, feel free to read the [HOWTO](HOWTO.md) to discover more practical and advanced examples which might solve specific problems you're facing.

Also make sure to read the [EXPLAIN](EXPLAIN.md) document to get a general overview of how everything works.

Finally, have a look at the technical [REFERENCE](REFERENCE.md) to know exactly what's going on behind the scenes, along with all function names, arguments, and settings.

## Menu

There are currently **five (5)** beginner tutorials. The first two can likely be skipped, but you'll need to start from the top if you can't get **"3. Your first queue"** to work.

  1. [Clone this repo](#1-clone-this-repo)
  2. [System check](#2-system-check)
  3. [Your first queue](#3-your-first-queue)
  4. [Queue information](#4-queue-information)
  5. [Cleaning up](#5-cleaning-up)

This library and documentation was created by [aw](https://github.com/aw). If you find or have any bugs, issues, or feature requests, please [create an issue](https://github.com/aw/picolisp-posixmq/issues/new).

You can also join the discussion on IRC channel `#picolisp` on the `irc.freenode.net` network.

---

# 1. Clone this repo

If you haven't cloned this repo yet, now's your chance:

```bash
git clone https://github.com/aw/picolisp-posixmq.git
cd picolisp-posixmq
```

---

# 2. System check

**Note:** `root` access will not be necessary for these tutorials.

### Check your OS

Ensure you have Linux with a kernel newer than `3.5`.

```bash
# should display 'Linux'
uname -s

# should display something similar to '4.4...' or '5.8...'
uname -r
```

### Check PicoLisp

Ensure you're running 64-bit PicoLisp newer than `v17.12`, or `pil21`

```bash
# should display something like '20.7.16'
pil -version -bye
```

### Check your kernel

Ensure your Linux kernel actually supports _POSIX Message Queues_

```bash
# should display CONFIG_POSIX_MQUEUE=y
zgrep CONFIG_POSIX_MQUEUE /proc/config.gz
```

If you don't have `/proc/config.gz`, try this:

```bash
# should display CONFIG_POSIX_MQUEUE=y
zgrep CONFIG_POSIX_MQUEUE /boot/config-$(uname -r)
```

### Check for librt

Ensure you have the POSIX Realtime Extensions library `librt.so`:

```bash
# should display at least one file named librt.so
find /usr/lib -name librt.so
```

If your OS has `libc`, it should also have `librt.so`.

### Check the filesystem

Ensure the `mqueue` filesystem is mounted correctly:

```bash
# should display 'mqueue on /dev/mqueue type mqueue (rw,relatime)'
mount | grep mqueue
```

If the output is different, try remounting the `mqueue` filesystem (requires root):

```bash
sudo mount -t mqueue mqueue /dev/mqueue
```

### Run the tests

Ensure all the tests pass:

```bash
# should display all tests passed, '0 tests failed' on the last line
make check
```

### System check OK

Congratulations! If you've made it this far, then you're ready to build your first queue.

---

# 3. Your first queue

In this tutorial we'll create a new queue, send some messages, and then read them.

### Load the library

From the Linux command line, start your PicoLisp interpreter:

```bash
pil +
```

Then load the library:

```picolisp
(load "mqueue.l")
```

### Create a queue

Create a new read/write queue named `/myqueue` with the command below:

```picolisp
(setq *Fd (pmq-open "/myqueue"(list O_RDWR O_CREAT)))
```

You should see some output stating that the queue name `/myqueue` was opened.

### Send a message

Send a few messages to the queue:

```picolisp
(pmq-send *Fd "Hello World")
(pmq-send *Fd "It works!")
(pmq-send *Fd "OK")
```

You should see some output stating that you've sent some messages.

### Read a message

Now, read one message from  the queue and print it to the screen:

```picolisp
(prinl (pmq-receive *Fd))
```

You should see some output stating that your first message, "Hello World", was received successfully. Try it again:

```picolisp
(prinl (pmq-receive *Fd))
```

Did you see "It works!" ? Let's leave the 3rd message in the queue, for now.

### Close the queue

When you're finished working with a queue, it's a good idea to close it:

```picolisp
(pmq-close *Fd)
```

If all went well, you should see the queue was closed. Now you can exit the PicoLisp interpreter and move-on to the next tutorial.

```picolisp
(bye)
```

---

# 4. Queue information

In this tutorial, we'll learn how to inspect the queue through the command line and directly through PicoLisp.

### Command line

From the Linux command line, your queue should still be visible in the filesystem, try this:

```bash
ls /dev/mqueue/
```

You should see a special file with the name of the queue created in Tutorial 3, `myqueue`. Don't worry, it doesn't take up any disk space (it's all in memory), and you're free to inspect it:

```bash
cat /dev/mqueue/myqueue
```

It shows the size of the queue (total size of all messages in the queue, in Bytes), as well as any _notify_ options enabled on the queue. Those can be ignored for now.

Notice the `QSIZE:3` ? That last message we sent, `OK`, includes a [null byte](https://en.wikipedia.org/wiki/Null_byte) at the end, which is why the size is 3 bytes instead of 2.

When a queue is closed, unread messages will remain, even after your application terminates.

### PicoLisp

Let's load the PicoLisp interpreter once more, and inspect the queue from there:

```bash
pil +
```

and from PicoLisp, we'll need to open the queue first. Let's do it in read-only mode:

```picolisp
(setq *Fd (pmq-open "/myqueue"))
```

Notice how we omitted many arguments? That's because the queue defaults to being **opened read-only**, assuming it already exists. You can learn more about the command arguments in the technical [REFERENCE](REFERENCE.md) documentation.

### Get queue information

Let's read the queue attributes:

```picolisp
(pmq-getattr *Fd)
```

You should see some output showing additional attributes of the queue, including the `Maximum size` and `Maximum number` of messages, the `Flags` provided at queue creation, and the `Current number of messages` sitting in the queue.

See how there's still **one (1)** message in the queue?

Now let's close the queue again:

```picolisp
(pmq-close *Fd)
```

Great! Let's move to the final tutorial.

---

# 5. Cleaning up

Once you're finished working with the queue, if there's still messages which you don't necessarily want to read, you can quickly cleanup by simply deleting the file:

```picolisp
(pmq-unlink "/myqueue")
(bye)
```

You should see the queue was removed (unlinked).

Another option, from within the command line, is to type:

```bash
rm /dev/mqueue/myqueue
```

Since you've already unlinked it from within PicoLisp, the command above will most likely fail with an error.

---

Now that you've completed all the beginner tutorials, you're ready to read the other documents below:

  * [HOWTO](HOWTO.md): a set of recipes for performing more advanced tasks with this library
  * [EXPLAIN](EXPLAIN.md): an explanation of some key concepts, including how this library works
  * [REFERENCE](REFERENCE.md): technical information on the internals of this library

# License

This documentation is Copyright (c) 2020~ Alexander Williams, On-Prem <license@on-premises.com>, and licensed under the [Creative Commons (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/) license.
