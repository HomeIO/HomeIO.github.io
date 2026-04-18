---
title: 'Setting Up a Wind Turbine'
date: 2007-01-01
draft: true
topics: ['energy']
tags: ['wind', 'renewable', 'diy']
description: 'Setting up a small wind turbine — planning, installation, and first results.'
---

## Why?

This is the start of one of my longest-running projects. We found wind turbines being sold on Allegro.pl. To be honest, I don't remember **why** we decided to buy one. I do remember the initial hardware was **not ready**.

We bought 4x gel batteries which cost about >1000 PLN at the time. Quite expensive compared to current (2026) battery prices and capacity.

### Braking system

In theory the wind turbine should brake mechanically by turning 90 degrees to the wind at high speed. It didn't. So I had to build a braking device. It used a high-power resistor to first slow down the turbine by putting resistance on all coils. After a second, other switches short-circuited all coils to make resistance as low as possible. The turbine was nearly not rotating after that.

## Accident

One late November night, high winds were predicted. We had an old APC UPS converting 48V from the batteries, because the inverter included in the kit was not good enough. I turned on a vacuum cleaner to use up the energy being generated. The current swung between 3–20A from second to second. A very big swing.

A few hours later I noticed I lost connection to the turbine. The blades were spinning like a helicopter. Not a good thing. A Chernobyl-series kind of accident. Next day winds dropped and we lowered the whole turbine.

From that moment I knew we needed a control system. Something that could monitor all vital parameters and allow remote control. Keep in mind this was long before Home Assistant, Zigbee, and similar technologies.

And that's where a lot of my ideas started.

## Lessons learned

- Don't trust cheap niche products to work out of the box.
- Wind is stochastic and complicated by nature.
- Gel batteries are decent, but not good enough.
