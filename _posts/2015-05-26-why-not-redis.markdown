---
layout: post
title:  "Why not Redis?"
date:   2015-05-26 19:00:00
categories: article
tags: [software]
---

[redis-list]:           http://redis.io/topics/data-types

Because Redis would store values in [list][redis-list] as string
while measurements are *unsigned int* objects.
That lead to massive memory usage or would not allow to have big
measurement buffer in memory.

This is the main reason I have rewritten backend in C++.

If I remember correctly redis used about 40-50% memory, when C++
version took max 3%. I am not sure about buffer size, it is
possible that I have used much bigger buffer in C++ version.
