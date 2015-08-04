---
layout: post
title:  "Spyware and buffer storage"
date:   2015-06-02 12:00:00
categories: news
tags: [software, news]
---

I wanted to have something like centralized place to check measurement and if all instances are working.
Had some problems with HTTP requests in C++ so I did something ugly - run curl command. It works.

Next feature is periodically store measurements from RAM to file. It works, but there are problems while
restarting. I need to check it. I need to remove *buffer files* before running backend.

I've fixed bug when storing measurements (not buffer) in csv files. Everyone should remember about
*return* in functions returning values. It's a bad habit from working in Ruby.