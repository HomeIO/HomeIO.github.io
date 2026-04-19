---
title: 'Setting Up a Wind Turbine'
date: 2007-11-09
draft: false
topics: ['energy']
tags: ['wind', 'renewable', 'diy']
description: 'A cheap wind turbine, a homemade braking system, and a November storm that changed how I think about control systems.'
math: true
---

## The setup

This was 2007. Photovoltaic panels were exotic and expensive. If you wanted to generate your own electricity in Poland, wind was about the only option. We found small wind turbines being sold on Allegro.pl — Chinese-made kits, 1kW rated, 48V output. To be honest, I don't remember **why** we decided to buy one. Curiosity, probably.

The kit came with blades, a three-phase permanent magnet generator, and a cheap inverter (48V → 230V AC — I'm not sure it even produced a pure sine wave). We added 4× gel batteries, which cost over 1,000 PLN at the time — expensive compared to what you'd pay for lithium cells today.

The whole package looked like the design team had only thought about the happy path.

## The braking system

In theory, the turbine should brake mechanically by turning its tail 90° to the wind at high speed. It didn't.

So I built a braking device. First stage: high-power resistors connected across all three coils to slow the rotor down through electrical resistance. After about a second, relays short-circuited all coils — dropping resistance as low as possible. The turbine was nearly stopped after that.

Braking took a few seconds. All the kinetic energy stored in the spinning blades was converted to heat, dissipated in the resistors.

How much energy is that? I don't have specs from the original turbine, but a [comparable Chinese 1kW unit](https://bessent.en.made-in-china.com/product/bfZryBRxgmcP/China-Small-Size-3-5-Blades-1kw-24V-48V-Horizontal-Axis-Wind-Turbine-Generator.html) (Bessent NE-1000M5, 3 blades, 48V, 3-phase permanent magnet AC) weighs 19 kg total. Subtracting the generator, tail, and mount, the rotor is probably 6–9 kg — roughly 2–3 kg per blade at ~1.5m length.

Approximating each blade as a uniform rod rotating about one end, the [moment of inertia][moment-of-inertia] is:

$$I_{blade} = \frac{1}{3} m L^2$$

For three blades (hub contribution negligible):

$$I_{total} = 3 \times \frac{1}{3} m L^2 = m L^2$$

The rotor speed depends on wind — the [tip-speed ratio][tsr] (TSR) for cheap 3-blade turbines is typically 4–6. At high wind speeds when braking matters most, the blades spin fast. Taking rated wind (~12 m/s) as an example:

$$\omega = \frac{\text{TSR} \times v_{wind}}{R}$$

The kinetic energy stored in the spinning rotor:

$$E_k = \frac{1}{2} I_{total} \; \omega^2$$

These are rough estimates — I don't have the exact blade mass or RPM data from our turbine. But plugging in reasonable assumptions gives an idea of the scale:

| Assumption | Blade mass | TSR | ω (rad/s) | RPM | E_k |
|---|---|---|---|---|---|
| Conservative | 2 kg | 5 | 40 | ~380 | ~3.6 kJ |
| Upper estimate | 3 kg | 6 | 48 | ~460 | ~7.8 kJ |

During braking, all of this kinetic energy gets converted to heat in the three 5Ω resistors over a few seconds. That's roughly **400–870W average per resistor** — and the peak power at the start is even higher, since power drops with ω² as the rotor decelerates. These numbers apply at rated wind speed; in storm conditions with the rotor spinning even faster, the energy scales with the square of RPM.

That's why the resistors had to be serious, high-power units bolted to a heat sink.

## The accident

One late November night, high winds were predicted. We had an old APC UPS converting 48V from the batteries, because the inverter from the kit wasn't good enough. I turned on a vacuum cleaner to burn off the energy being generated. The current was swinging between 3 and 20 amps from second to second. A wild ride.

A few hours later I noticed I'd lost connection to the turbine. The blades were spinning like a helicopter. A Chernobyl-series kind of moment. The next day winds dropped and we lowered the whole assembly.

## What came next

From that night I knew we needed a proper control system — something that could monitor all vital parameters and allow remote braking. Keep in mind, this was 2007. No Home Assistant, no Zigbee, no cheap microcontrollers with WiFi. Building that system meant designing the hardware and software from scratch.

That led to building the first iteration of wind turbine firmware — a microcontroller monitoring voltage, current, and RPM, with a simple backend and a web frontend for remote control. A few years later, that system grew beyond the turbine. It became a general-purpose home monitoring platform — the first version of what I eventually called HomeIO, which is also the name of this blog.

But the seed was that November night and a turbine spinning out of control.

## Lessons learned

- Don't trust cheap products to work outside the happy path. The mechanical braking, the inverter, the overall system design — all failed under real conditions.
- Wind is stochastic by nature. Equipment needs safe margins for the worst case, not the average case.
- Gel batteries were decent for 2007, but the energy density and cycle life were poor compared to what's available now.
- If you can't monitor it, you don't know what's happening. The turbine had no telemetry — we only found out it failed because the connection dropped.

[moment-of-inertia]: https://en.wikipedia.org/wiki/Moment_of_inertia
[tsr]: https://en.wikipedia.org/wiki/Tip-speed_ratio
