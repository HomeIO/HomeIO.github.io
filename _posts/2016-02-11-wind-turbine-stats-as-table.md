---
layout: post
title:  "Wind turbine statistics addon is more pretty now"
date:   2016-02-11 09:00:00
categories: news
tags: [software, news]
---

A better one
------------

I have changed addon interface to allow better representation of current
state of system. You can see history of various parameters from latest one.

Parameters
----------

Theese parameters are:

* `time` - hour
* `work` - generated energy in Wh but in file there is in Joules)
* `coil time` - time of working turbine by coil voltage higher than 5V
* `batt time` - time of working turbine by charging current higher than 0.5A
* `res time` - time of working resistor as a brake
* `max b curr` - maximum charging current
* `max b v` - maximum battery voltage
* `max coil v` - maximum voltage on coil (one preselected)

Sample image
------------

![Wind turbine statistics](/images/nc_addon_wind_stats.png)


TODO
----

* fix interval rounding to use round (without round it `floor` value)
