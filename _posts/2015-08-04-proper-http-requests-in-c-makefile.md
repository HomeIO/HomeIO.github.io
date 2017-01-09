---
layout: post
title:  "Proper HTTP requests in C++, makefile and small portion of fame on Nukomeet blog"
date:   2015-08-04 12:00:00
categories: news
tags: [homeio, software, news]
---

Fame
----

[Nukomeet](http://nukomeet.com) featured my [article](http://nukomeet.com/2015/07/plant_survivor/)
about HomeIO and plant monitoring system. Thanks! :)


Makefile
--------

I used script files to run backend cleaning, compilation and run it to various systems. Now it's the *makefile* !

If you want to run just type:

```
make run SITE=dev
```

SITE variable tells which instance to run. Instance is defined by proper *main* file in /src/mains.


Proper HTTP requests
--------------------

I've integrated *libcurlpp* and now all spy requests are done in a good way. The bad thing is that you need to
install more dependencies on your system.

For Debian users you can

```
make debian-deps
```

or

```
sudo apt-get install libcurl4-openssl-dev git g++-4.9 cpp-4.9 libcurlpp0 libcurlpp-dev
```

The **libcurlpp0** **libcurlpp-dev** Debian packages are required from now additionaly.
