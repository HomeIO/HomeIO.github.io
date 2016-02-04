---
layout: post
title:  "Shared pointers"
date:   2016-02-04 22:00:00
categories: news
tags: [software, news]
---

The best lazy solution to memory leak
-------------------------------------

Shared pointers allow me to utilize power of pointers without thinking
about memory deallocation - `delete` function.

Overhead in that method is max 1-3% depends on compiler.

At this moment only ncurses related code is not using shared pointers.
