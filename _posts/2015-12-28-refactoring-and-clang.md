---
layout: post
title:  "Refactoring and clang support"
date:   2015-12-28 22:00:00
categories: news
tags: [software, news]
---

Refactoring
-----------

I'm in the middle of refactoring to more proper code structure: header structure
and all code (`*.cpp`) files as input for compiler. My friend told me that approach
is much more secure, and allow to detect errors much more easily.

I've managed to make backend compilable and run it on local instance for tests,
but there is a some work to do.

clang
-----

I've managed to allow to compile backend using clang. I've always used GCC, and
I'm not going to change it.

Clang is much more verbose and detects other types of errors (or warnings). Testing
on both compilers allow creation of much more portable code.

ncurses
-------

I'm thinking about using some basic text interface, but allow to change to old
log-style output.

This should make backend process much more readable and usable.
