---
layout: post
title:  "What is HomeIO"
date:   2015-05-24 12:00:00
categories: article
tags: [homeio, software]
---

[redis-list]:           http://redis.io/topics/data-types
[tutorials]:            /tag/tutorial


What is HomeIO?
---------------

HomeIO it is the family of utilities created to monitor and control
various systems onlive via web application. Everything is free (as
free software) and open source.

It is short description. Detailed posts are coming soon.

Layers
------

It consists of 3 layers:

1.  firmware
2.  backend
3.  frontend

Firmware
--------

At this moment there is only sample Arduino firmware available, but the
most important thing is *communication protocol*.

Firmware gets commands from backend and return outputs. Most of theese
commands are *get measurement* command. Then there are *execute action*
commands, and some minor utility commands.

Backend
-------

Backend server must be run on Gnu/Linux. BSD and other were not tested.
It periodically get measurements and store in internal buffer, which is
much better than [Redis lists][redis-list].

Frontend
--------

It is pretty obvious what is it. Fun part is that it require no configuration.
It fetch everything from backend and everything is processed in client side
for maximum performance.

Where can it be used?
---------------------

I use it with small wind turbine, and the second instance with plants
to monitor soil moisture.

Wind turbine sample graph:

![Multigraph sample](/images/homeio4.png)

Plants sample graph:

![Multigraph sample](/images/homeio3.png)

If you have questions possible usage feel free to ask via email.


How to start?
-------------

Please check [tutorial posts][tutorials].
