---
layout: post
title:  "Cmake is awesome"
date:   2016-02-02 22:00:00
categories: news
tags: [homeio, software, news]
---

My friend told my about [`cmake`](https://cmake.org/) that it is his favourite
building tool.

At start I had big problem to understand how this tool works. I need to create simple
"hello world" program and compile it. Next thing was try to integrate with HomeIO and
from that point it started to work quite fast.

The biggest pros of `cmake` is that if make compiling much faster
in development by compiling only what has been changed. After compile error I don't have
to wait to compile what was already done.

There are some things to do, like put some `cmake` snippets in better format than
shell scripts. I don't want to use `makefile` to run another `makefile`.
