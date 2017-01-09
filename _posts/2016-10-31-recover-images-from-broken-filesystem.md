---
layout: post
title:  "Recover images from broken filesystem."
date:   2016-10-31 15:00:00
categories: article
tags: [linux, software]
---

[raspbian]: https://www.raspberrypi.org/downloads/raspbian/

Case
----

I was installing [Raspbian][raspbian] on microSD card and put wrong card into my laptop.
After flashing [Raspbian][raspbian] on it I've found it was the card used by my parents compact
camera. I thought all data was lost.

Searching for tool
------------------

Quite a few years ago I had my last attempt at recovering data from
failing HDD disk, and I was using the most popular commercian windows tool
(it was probably
[Ontrack](http://www.toptenreviews.com/software/backup-recovery/best-data-recovery-software/))

I'm using exclusively GNU/Linux on laptop now so I cannot use windows tools
so I need to do some research.

The best results I've got using [`foremost`](http://foremost.sourceforge.net/)
which search image for JPEG begin and end file signatures.

Process
-------

First we need to copy data from device with broken filesystem. **This is dangerous
process if you mistake source with destination**.

```bash
dd if=/dev/sdb of=sd.img bs=1MB
```

Next create directory where you want output JPEGs to be stored. I hope you don't
need to readt how to create directory `mkdir output`.

The last part, apart of checking output, is to run recovering tool.

```bash
foremost -t jpeg -i sd.img -o output/
```

* `-t jpeg` - it has predefined some types of files which can try to recover.
  I haven't tried other types.
* `-i sd.img` - image of whole device copied using `dd`
* `-o output/` - recovered files with report will be put there
