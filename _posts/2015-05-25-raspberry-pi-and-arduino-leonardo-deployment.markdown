---
layout: post
title:  "How to deploy HomeIO on Raspberry Pi + Arduino Leonardo"
date:   2015-05-25 15:18:59
categories: tutorial
tags: arduino raspberry deployment tutorial
---

[arduino-leonardo]:             http://www.arduino.cc/en/Main/ArduinoBoardLeonardo
[arduino-leonardo-shield]:      http://mlm-s2-p.mlstatic.com/sensor-shield-v50-expansion-para-arduino-uno-leonardo-mega-16954-MLM20129830675_072014-O.jpg
[raspberry]:                    https://www.raspberrypi.org/
[raspbian]:                     https://www.raspbian.org/
[raspbian-install-to-sd]:       http://www.instructables.com/id/How-to-install-Rasbian-Wheezy-on-the-Raspberry-P/

Why Arduino?
============

HomeIO can be deployed on typical Gnu/Linux server connected with _hardware_. Arduino is the
most common hardware platform available now, so first tutorial will utilize it as a hardware.

I recommend using Arduino Leonardo, because it's the most popular model and Raspberry Pi has
no problems with powering it. [More info here][arduino-leonardo].

It is a good thing to buy proper _sensor shield_. It is an external board which you plug onto
Arduino and allow it to connect multiple sensors very easily. [This board looks like this][arduino-leonardo-shield].

TODO: add photos

The server
==========

You can use nearly every PC as a server for HomeIO. Keep in mind power usage. (There are also
other requirements, but I can not specify them all)

[Raspberry Pi][raspberry] has very low power usage and is powerful enough to allow 
HomeIO deployment. In this tutorial I will choose it as a server platform. If you have other PC
everything should be similar.

Preparing server
================

I prefer Debian distribution, so you can install [Raspbian][raspbian]. [How to install][raspbian-install-to-sd].

You need quite fresh packages repository. In case of Raspbian I recommend you to change to _jessie_ because
HomeIO needs C++ compiler version 4.9. I'm not sure about version of Go language needed at this moment.

```
apt-get install g++-4.9
```

```
apt-get install go-lang
```

Configure backend
=================

TODO measurements, actions, overseers

TODO examples with moisture sensor

Run frontend
============

TODO go path

Result
======

![Multigraph sample](/images/homeio4.png)