---
layout: post
title:  "Ncurses interface"
date:   2016-01-30 22:00:00
categories: news
tags: [homeio, software, news]
---

New interface
-------------

HomeIO was created as a server-like application which everything important is
rendered as log-like response.

Wind turbine instance is very dynamic. There was too much of information rendered
too fast. It was nearly not readable at all. I need to change it.

I wanted to try [ncurses](https://www.gnu.org/software/ncurses/) as one of the
most popular tool to create console interface. It was quite some work which
allowed me to perform a lot of other changes and fixes.

Now, you can see current measurements without using [frontend](https://github.com/HomeIO/homeio_frontend).

Tabs
----

Interface consist of various tabs which I will describe below.

* Home - status of all modules, boot and shutdown
* Log - last log messages, scrollable
* Meas - current measurements
* Action - list of actions
* Overseer - list of overseer: current state, measurement and executable action
* Addons - every addon has its own page
* Stats - at this moment only resource usage stats

![Measurement UI](/images/nc_meas.png)

Future
------

I want to add theese features soon:

* Better addons interface: wind turbine with more meaningful data, ...
* Some actions can executable from interface. It will be probably accessible by
  addon page.
* More stats
