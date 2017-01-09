---
layout: post
title:  "You can safely press CTRL+C"
date:   2015-09-09 22:00:00
categories: news
tags: [homeio, software, news]
---

Till this day pressing CTRL+C had some bad effects, now it's safe* to restart backend.

*it *should* be :)

First was fixing locked TCP socket issue, which I've done it a few months ago. About month ago I had an idea that it's not nice to kill
backend process while it write measurements. As you know (or now) backend store two versions: stored CSV (name, time from, time to, value)
and buffer (all data fetched from uC, but not more than million of raw values per measurment type). Image pressing CTRL+C while backend does it.
It would be not nice - data loss (keep in mind HomeIO is not intended to enforce persistence).

For about 3 weeks if you press CTRL+C signal execute close procedure which close all subsystems in a proper order. Good, but not awesome. It
won't stop storing data. Since today measurements are stored after stop is initialized, so all measurements that are in memory *should* be
read after you restart.
