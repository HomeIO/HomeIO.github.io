---
layout: post
title:  "New sensors in local instance!"
date:   2015-09-09 21:00:00
categories: news
tags: [hardware, news]
---

[analog-temp]:                  http://www.ti.com/lit/ds/symlink/lm35.pdf
[digital-tmp-hum]:              http://akizukidenshi.com/download/ds/aosong/AM2302.pdf

Hardware
--------

Some time ago I bought a few sensors. Two of them were: 

* analog temperature senson [LM35][analog-temp],
* digital humidty and temperature senson [AM2302][digital-tmp-hum]

A few days ago I had time to use them in local HomeIO instance. 

Digital sensor is much more accurate than analog. Digital sensor has 0.1&deg;C resolution, while analog one has 0.5&deg;C 
effective resolution when using ADC converter. You can change reference voltage to increase resolution, but it's not recommended
in present situation, when there are other analog sensors.

Outcome
-------

I bought another digital one and installed it outside few moments ago. I hope this will result in interesting conclusions over time.

Measurements:

* internal temperature - 21.4 &deg;C
* internal humidity - 45.2 %
* external temperature - 13.3 &deg;C
* external humidity - 69.5 %