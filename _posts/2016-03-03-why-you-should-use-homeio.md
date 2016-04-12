---
layout: post
title:  "Why you should use HomeIO?"
date:   2016-03-03 12:00:00
categories: article
tags: [software, news]
---

* [Low hardware requirements](#why1)
* [Fast access to measurements](#why2)
* ["Everything in backend" philosophy](#why3)
* [Web frontend - just run it](#why4)
* [NCurses console interface](#why5)
* [It's free - GPL licence](#why6)


<a name="why1"></a>

Low hardware requirements
-------------------------

You can easily deploy it on [Raspberry Pi](https://www.raspberrypi.org/) or any
low-end computer. One of it instances works on [Raspberry Pi B](https://www.raspberrypi.org/products/model-b/)
with only 512MB of RAM.

There are some requirements your computer need to meet:

* it has run on GNU/Linux or \*Nix
* it has to be connected to *HomeIO hardware*, for example: [Arduino]({% post_url 2015-05-25-raspberry-pi-and-arduino-leonardo-deployment %})

Wind turbine instance utilizes **only 15%** of [Raspberry Pi](https://www.raspberrypi.org/)
CPU when not performing store/restore of a whole measreuments buffer.

Imagine that it gets 10 types of measurements, all every about 150ms and do lot of
processing.

![Top on Raspberry Pi B](/images/rasp_wind_top_command.png)


<a name="why2"></a>

Fast access to measurements
---------------------------

There is *measurement buffer* which store every fetched raw value of measurement.
Every one raw value is only `unsigned int` in already allocated `std::vector`. There is no time
information per value, rather it use interval. Small time inaccuracy is acceptable.

**The memory usage is the most efficient as possible. Just plain raw values in RAM.**

That means if you want to see a graph there is no IO operation.

Measurements are archivized in CSV file in format:

`name; time_from_miliseconds; time_to_miliseconds; value_as_float`

It will be easily processable in future, but in my experience you will
rarely want to do it.



<a name="why3"></a>

"Everything in backend" philosophy
--------------------------------

**Everything what you need to set up is in the `main` file.**

Just one file! Run it and frontend will fetch everything needed.

The only exceptions are:

* addons - which you can write own from scratch
* frontend password to execute actions - double hashed string using md5



<a name="why4"></a>

Web frontend - just run it
--------------------------

Just run frontend application, setup your router and you can see what your
system is doing.

Just like backend, the frontend was also designed to be resource friendly.
Frontend acts like a proxy between web browser and backend. Everything
is generated in backend, and send as a JSON to web browser.

**All processing to render graph is performed in client space.**
Graphs are rendered using [flot](http://www.flotcharts.org/).

![Frontend request times on Raspberry Pi B](/images/rasp_wind_web_log.png)

As you can see above theese requests needed to render graph **were served in less than
50ms on Raspberry Pi B!**

Keep in mind if our frontend is not what you need feel free to write your own.


<a name="why5"></a>

NCurses console interface
-------------------------

If you not want to run frontend backend allow you to see what backend is doing,
you can use simple console interface.

![HomeIO measurements ncurses console](/images/nc_meas.png)


<a name="why6"></a>

It's free - GPL licence
-------------------------

If you want and know how to feel free to use HomeIO for free.
