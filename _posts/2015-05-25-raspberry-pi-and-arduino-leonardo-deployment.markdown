---
layout: post
title:  "How to deploy HomeIO on Raspberry Pi + Arduino Leonardo"
date:   2015-05-25 15:18:59
categories: article
tags: [arduino, raspberry, deployment, tutorial, software, hardware]
---

[arduino-leonardo]:             http://www.arduino.cc/en/Main/ArduinoBoardLeonardo
[arduino-leonardo-shield]:      http://mlm-s2-p.mlstatic.com/sensor-shield-v50-expansion-para-arduino-uno-leonardo-mega-16954-MLM20129830675_072014-O.jpg
[raspberry]:                    https://www.raspberrypi.org/
[raspbian]:                     https://www.raspbian.org/
[raspbian-install-to-sd]:       http://www.instructables.com/id/How-to-install-Rasbian-Wheezy-on-the-Raspberry-P/
[backend]:                      https://github.com/HomeIO/homeio_backend/
[backend-git]:                  https://github.com/HomeIO/homeio_backend.git
[backend-arduino-main.cpp]:     https://github.com/HomeIO/homeio_backend/blob/master/src/mains/main_arduino.cpp
[backend-wind-main.cpp]:        https://github.com/HomeIO/homeio_backend/blob/master/src/mains/main.cpp

Why Arduino?
------------

HomeIO can be deployed on typical Gnu/Linux server connected with _hardware_. Arduino is the
most common hardware platform available now, so first tutorial will utilize it as a hardware.

I recommend using Arduino Leonardo, because it's the most popular model and Raspberry Pi has
no problems with powering it. [More info here][arduino-leonardo].

It is a good thing to buy proper _sensor shield_. It is an external board which you plug onto
Arduino and allow it to connect multiple sensors very easily. [This board looks like this][arduino-leonardo-shield].

![Arduino Leonardo with sensor shield](/images/arduino_with_shield2.jpg)

The server
----------

You can use nearly every PC as a server for HomeIO. Keep in mind power usage. (There are also
other requirements, but I can not specify them all)

[Raspberry Pi][raspberry] has very low power usage and is powerful enough to allow
HomeIO deployment. In this tutorial I will choose it as a server platform. If you have other PC
everything should be similar.

Preparing server
----------------

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
-----------------

I assume you have similar system to monitor as I have - 3 plants with moisture sensor + 1 light sensor :)

Everything regarding backend is set in [backend code][backend-arduino-main.cpp]. Everything is in one place.
I have added comments in [wind turbine version][backend-wind-main.cpp], but I will try to describe it also.

To start git clone [backend repository][backend].

```
git clone https://github.com/HomeIO/homeio_backend.git
```

Fetch cycle
===========

HomeIO works by fetching measurements in cycles. There is measurement types array and it fetch every some time.

```
h->measFetcher->betweenMeasInterval = 10000;
```

That means there is 10000 microsecond = 10 miliseconds delay between fetching another measurement type. All delays are in microseconds,
but times are stored in miliseconds.

If all measurement types were fetched it waits for next cycle. You can set it here.

```
h->measFetcher->cycleInterval = 10000000;
```

That means there is 10000000 microsecond = 10000 miliseconds = 10 seconds delay between fetching another cycle. Soil
moisture and light is quite slowly changing thing. Note: in [wind turbine version][backend-wind-main.cpp] this is set to 50
miliseconds because of it is different kind of system.

Measurements
============

```
MeasType *m;
```

It is C++ definition of variable. If you don't understand it
[you're going to have a bad time][http://godlessmom.com/wp-content/uploads/2015/03/youre-going-to-have-a-bad-time.png].

```
m = new MeasType();
```

Create **MeasType** object. It represents everyting about one type of measurements.

```
m->name = "light";
```

It is the name of this measurement type. If you put some weird characters here and it breaks, it is your fault.
If you want get something regarding one type, you must use name for identification.

```
m->unit = "%";
```

It is only used in frontend.

```
m->command = '0';
```

Character command which is send to Arduino. Please check Arduino firmware info later.

```
m->responseSize = 2;
```

Response is 2 byte long. Analog to digital in AVR/Atmega is 10-bit so the response needs 2 bytes.

```
m->coefficientLinear = -0.09765625;
```

```
m->coefficientOffset = -1023;
```

Real value = ( raw value + _coefficientOffset_ ) * _coefficientLinear_. Both this parameters are used for calculation real
float value. If you do not know what to set you can remove theese lines. There are default values.

```
m->minTimeDiffToStore = 5000;
```

Apart of fetching measurements backend can do a lot of cool thins. One of them is storing values. It stores
them in CSV files in _data_ directory.

Example of stored measurement:

```
coil_1_u; 1432046783261; 1432046784395; 0.000000
```

It is: name; time _from_ (in miliseconds from 1970, the JS format); time _to_; real value

Setting **minTimeDiffToStore** tells backend not to store if last one was stored
within 5000 miliseconds from now.

```
m->maxTimeDiffToStore = 3600000;
```

Force store if last one was stored more or equal than 3600000 miliseconds from now, this
equals 1 hour.

```
m->valueDiffToStore = 3.0;
```

If current value changed more than 3.0 of real units then store. Keep in mind that two
previous conditions apply as priority.

```
m->priority = 1;
```

It is only used in frontend to separate more important measurements from less one.

```
h->measTypeArray->add(m);
```

Add measurement to fetchable measurement array.

Is that all?
============

Yes and no. This is the most important thing to start HomeIO with. Other parts will
be described soon.

Run frontend
------------

```
export GOPATH=~/gopath
```

Go needs path to store its stuff.

```
go get github.com/gin-gonic/gin
```

Frontend uses gin framework. You must run this one time only.

```
go run homeio.go
```

Run frontend. Keep in mind that backend is required to frontent to work. Everything
is fetched from backend. There is frontend configuration needed.

Result
------

![Multigraph sample](/images/homeio4.png)
