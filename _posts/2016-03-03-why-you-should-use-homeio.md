---
layout: post
title:  "Why you should use HomeIO?"
date:   2016-03-03 12:00:00
categories: article
tags: [software, news]
---

Low hardware requirements
-------------------------

You can easily deploy it on [Raspberry Pi](https://www.raspberrypi.org/) or any
low-end computer. One of it instances works on [Raspberry Pi B](https://www.raspberrypi.org/products/model-b/)
with only 512MB of RAM.

There are some requirements your computer need to meet:
* it has run on GNU/Linux or \*Nix
* it has to be connected to *HomeIO hardware*, for example: [Arduino](/article/2015/05/25/raspberry-pi-and-arduino-leonardo-deployment/)

Wind turbine instance when not performing store/restore whole buffer utilizes **only 15%**
of CPU.

Imagine that it gets 10 types of measurements all every about 150ms and has lots of
processing of them.

![Top on Raspberry Pi B](/images/rasp_wind_top_command.png)

Fast access to measurements
---------------------------

There is *measurement buffer* which store every fetched raw value of measurement.
Every one raw value is only `unsigned int` in pre-sized `vector`. There is no time
information per value, rather it is interval. There is small time inaccuracy.

**The memory usage is the most efficient possible. Just plain raw values in RAM.**

That means if you want to see a graph there is no IO operation.

Measurements are archivized in CSV file in format:

`name; time_from_miliseconds; time_to_miliseconds; value_as_float`

It will be easily processable for you in future, but in my experience you will
rarely want to do it.


Everything in backend philosophy
--------------------------------

**Everything whar you want to setup is in `main` file.**

Just one file! Run and frontend will fetch everything needed.

The only exceptions are:
* addons - which you can write own from scratch
* frontend password to execute actions


Web frontend
------------

Just run frontend application, setup your router and you can see what your
system is doing.

Just like backend, the frontend was also designed to be resource friendly.
Frontend acts like a proxy between web browser and backend. Everything
is generated in backend, and send as a JSON to web browser.

**All processing to render graph is performed in client space.**
Graphs are rendered using [flot](http://www.flotcharts.org/).

![Frontend request times on Raspberry Pi B](/images/rasp_wind_web_log.png)

As you can see theese requests needed to render graph **were served in less than
50ms on Raspberry Pi!**

NCurses interface
-----------------

If you not want to run frontend backend allow you to see what is doing in
simple console interface.

![Top on Raspberry Pi B](/images/nc_meas.png)
