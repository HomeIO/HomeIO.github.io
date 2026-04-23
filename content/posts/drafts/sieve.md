---
title: 'Finding patterns in measurements'
date: 2026-04-04
draft: true
topics: ['smart-home']
tags: ['home-assistant']
description: 'Is it possible to be independent of LLM by using LLM'
---

## Why

I've started storing raw measurements from Home Assistant locally. Normally it stores them for 10-14 days TODO: confirm it. I did it because I want to have most accurate data for some calculations like battery storage simulation. By using statistic data (1h window, average, min/max) I've noticed that when I want to calculate max power of inverted result is 2-3x times lower if I'd use raw measurements.

Having these measurements what can I do to analyze it? I can send it to LLM to find patterns and evaluate. But this is something hard to scale because LLM costs.

## Smarter way

What if I'd initialy send data to LLM? I cannot send all existing data so maybe start from daily ranges. LLM could look for interesting events, patterns, anything. If it find then we have information what is it, what we need to look after.

The next thing is to have something which could sweep through vast amount of sensor measurements and find similar events. These events needs to be somehow defined and, with huge help of LLM we managed to create a yaml structure for 
storing rules how to find these events. Or to allow using custom Go code to write more complicated rules (didn't do it yet to be honest).

TODO: later insert sample rule file

## Result

As for now I have a WIP version with scanned 10-20 days. LLM processing found some but it lacks "something". I don't know what but it's the human factor which LLM are missing.

TODO: what kind of rules we've found already?

TODO: not sure if it should be a project page instead of blog post, and blog post should cover initial steps and result? Or something else - blog post should cover what it has now but more project desc and create from it project page
