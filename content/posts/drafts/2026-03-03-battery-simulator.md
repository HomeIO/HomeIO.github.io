---
title: 'Finding patterns in measurements'
date: 2026-04-04
draft: true
topics: ['smart-home']
tags: ['home-assistant']
description: 'Is it possible to be independent of LLM by using LLM'
---

## Why

There are few important techs to decarbonize. One of the missing from my perspective is battery storage and EV. I've started analyzing and simulating battery storage from nearly a year. Having installed smart power meter for whole home I had it mind that it will give me important data for analyzing how big battery storage I need.

## 

Evolution of code of simulation is my adoption of LLM. First iterations was "organic", then I used LLM for creating parts of code or visulatization. Creating battery storage simulation was second or third app I've created using Claude. I've chosen Go as an experiment because Go and Python is the languaged I'm interested in learning (howevere we could argue if it's worth learning languages nowaday).

## Result

At this moment I'm not happy with this app. It's try to do too many things and it was heavily connected with other subprojects.

The most important right now is a small tool which is being run every 1h and fetch recent measurements from Home Assistant. It was all in one repository but I decided to split it and clean a bit. So now the only real used effect is storing all measurements in `input` path which later can be used by vast amount of other subprojects. And these subprojects are more interesting. Still `battery-simulator` also uses them but for me it's kinda death. It was nice PoC idea app which should be rewritten into something which would focus purely on analyzing cost of battery storage, and other calculating what happen with energy stored there, and other doing "other stuff". Modeling heat model of home and calculating saving when temperature would be 1C lower was wrong idea.
