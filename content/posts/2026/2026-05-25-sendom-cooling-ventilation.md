---
title: "Cooling and Ventilation Strategies for a sendom.pl House — What the Sensors Reveal"
date: 2026-05-25
tags: ["energy", "ventilation", "thermal-modeling", "home-assistant", "sendom", "cooling", "heatwave"]
description: "Real sensor data from a Sendom house near Poznań reveals which ventilation and cooling strategies actually work — from cross-ventilation events to heatwave simulations."
topics: ["energy", "home-automation"]
math: true
---

In the [previous post](/posts/2026/2026-05-04-sendom-thermal-model/) we modelled how this <a href="https://sendom.pl" target="_blank">Sendom</a> house *retains* heat. Here we look at the opposite problem: **how it gets rid of heat** — and what you can do to help it.

Cooling a well-insulated house is harder than it sounds. The same thick walls and airtight envelope that keep warmth in during winter also trap heat during summer. When outdoor temperatures hit 30–35 °C, the house becomes a slow-cooking oven. The question is not whether to ventilate, but **when, how much, and with what strategy**.

We analysed six months of sensor data, ran a calibrated thermal model, and simulated heatwave scenarios up to 2050. Here is what actually works.

---

## The Sensors: Three Temperatures, Three Stories

The main bedroom has three temperature sensors. They do not agree. Understanding why is the key to interpreting everything else.

| Sensor | Location | Height | Behaviour |
|--------|----------|--------|-----------|
| **Zigbee bedside** (`TEMP_BEDROOM1`) | Near the bed, close to the window | ~0.8 m | Fast, accurate, captures air temperature changes |
| **Zigbee ceiling** (`TEMP_BEDROOM2`) | Mounted high on the wall | 2.5 m | Reads 1–2 °C warmer due to thermal stratification |
| **Netatmo central** (`NETATMO_BEDROOM_TEMP`) | Shelf in the centre of the room | 2.5 m | Reads warm, misses rapid changes, occasional dropouts |

The high-mounted sensors are in the **warm air layer** that accumulates near the ceiling. In a heated room, the vertical temperature gradient is typically 1–2 °C per metre. A sensor at 2.5 m measures the ceiling temperature, not the temperature where people actually live.

For ventilation analysis, we use the **bedside sensor** as ground truth. It is the only one that captured what actually happened during our ventilation experiments.

---

## Experiment 1: Cross-Ventilation on a Winter Afternoon

On 27 February 2026, we opened **both bedroom windows** at 16:45. Outdoor temperature was ~8 °C. Wind was 5–10 km/h. The windows stayed open until ~18:35.

### What the sensors recorded

| Sensor | Before (16:45) | Minimum | Drop | Recovery (22:00) |
|--------|----------------|---------|------|------------------|
| Zigbee bedside | 22.9 °C | **17.9 °C** at 17:38 | **−5.0 °C** | 20.8 °C |
| Netatmo central | 23.3 °C | 22.1 °C at 18:33 | −1.2 °C | 23.0 °C |

The bedside sensor dropped **5 °C in 53 minutes**. The Netatmo, mounted high and further from the window, barely noticed — it lost only 1.2 °C and only reached its minimum after the windows were already closed.

This is not a sensor failure. It is **thermal mass lag and stratification** in action. The high sensor is embedded in the room's thermal mass (walls, furniture, warm air layer). The bedside sensor is in the **air stream** entering through the window. It measures what the occupants feel.

### CO₂ flush

CO₂ dropped from **1,374 ppm to 428 ppm** in 110 minutes — a rate of **−8.6 ppm/min** at peak. Cross-ventilation with two windows open is brutally effective at clearing stale air.

### The humidity puzzle

Relative humidity spiked from 45% to 68% during ventilation. This looks like the room got more humid. It did not. Cold outdoor air (8 °C, 80% RH) has low absolute moisture content. When it enters the warm room, its relative humidity drops — but because the room itself is cooling, the **relative** humidity rises even as the **absolute** humidity falls.

Absolute humidity dropped from 9.2 g/m³ to 7.8 g/m³. The "humidity spike" is a temperature illusion.

---

## Experiment 2: Mechanical Ventilation Speed Matters

The house has a Zehnder ComfoAir HRV unit. We compared two empty-room days at different speeds:

| Setting | Speed | Empty-room CO₂ decay | Time to near-outdoor |
|---------|-------|----------------------|----------------------|
| Speed 1 | Low | ~2 ppm/min | ~6 hours |
| Speed 3 | High | ~6 ppm/min | ~2 hours |

Speed 3 clears CO₂ three times faster. But here is the surprise: **indoor temperature stayed stable at both speeds**. The HRV recovers heat from exhaust air, so even at high speed the thermal penalty is small. This is exactly what the HRV is for — you can ventilate aggressively without freezing the house.

The limitation is noise and power consumption, not temperature. For overnight sleeping, Speed 1 is probably the right compromise.

---

## Experiment 3: Morning Ventilation Strategy

On hot summer days, the classic Polish strategy is: *open windows at night, close them in the morning, keep shutters down during the day*. We wanted to know: **what is the optimal closing time?**

We ran a calibrated thermal model (validated against real data — see below) with actual weather from 25 May 2026. Morning low was 13.7 °C, afternoon high reached 25.9 °C.

### Strategy comparison

| Strategy | Sunset temperature | Notes |
|----------|-------------------|-------|
| Baseline (closed all day) | 25.6 °C | House cooks |
| Open 06:00, close 10:00 | 21.2 °C | Best balance |
| Open 06:00, close 10:30 | 21.9 °C | Slightly warmer, more ventilation |
| Open 08:00, close 10:00 | 24.0 °C | Less cooling, less risk |

The optimal strategy is: **open at 06:00, close when outdoor temperature catches up to indoor** — around 10:00–10:30 on that day. Earlier opening gives more cooling but requires getting up earlier. Later opening is safer but less effective.

### Validation against reality

On 25 May 2026, the actual window was opened at 06:07 and closed at 08:27. The bedside sensor recorded:

- 06:00: 21.8 °C
- Minimum: 18.8 °C at ~07:00
- 08:30: 20.0 °C

The model predicted **19.0 °C minimum** and **19.5 °C at 08:30** — within **0.5 °C** of reality. The main discrepancy on earlier runs was using a weather forecast that underestimated morning temperatures by 3–4 °C. Once we fed the model actual outdoor sensor data instead of the forecast, accuracy improved dramatically.

---

## Experiment 4: Heatwave Analysis — What Happens at 40 °C?

We extended the model to simulate extreme heatwaves: outdoor temperatures from 30 °C to 40 °C, with morning lows from 15 °C to 25 °C. We tested six strategies:

1. **Baseline**: windows closed, shutters up
2. **Night ventilation**: open 22:00–06:00, shutters up
3. **Night ventilation + shutters down**: open at night, block solar gain during day
4. **Morning ventilation**: open 06:00 until outdoor ≈ indoor, then close + shutters down
5. **Zehnder 40%**: mechanical ventilation + shutters down
6. **Cross-ventilation AM**: open 06:00–08:00, then close + shutters down

### Results for an extreme day (morning 15 °C, noon 40 °C)

| Strategy | Sunset temperature | Cooling vs baseline |
|----------|-------------------|---------------------|
| Night + shutters | **24.7 °C** | **−17.5 °C** |
| Morning vent | 29.3 °C | −12.9 °C |
| Cross-vent AM | 30.5 °C | −11.7 °C |
| Zehnder 40% | 31.6 °C | −10.6 °C |
| Night vent (no shutters) | 35.5 °C | −6.7 °C |
| Baseline | 42.2 °C | — |

**Shutters dominate.** Without them, even night ventilation leaves the room at 35.5 °C. With shutters down, the same ventilation strategy hits 24.7 °C — a 17.5 °C improvement.

The ground floor shutters block **95% of solar gain**. The bedroom shutters, in "blocking mode," block **70%**. This is the single most important factor for summer comfort.

### Strategy ranking across all scenarios

"Night + shutters" won **100%** of the 25 temperature combinations we tested. It is never worse than any other strategy. The ranking is:

1. **Night + shutters** (always best)
2. Morning vent
3. Cross-vent AM
4. Zehnder 40%
5. Night vent (no shutters)
6. Baseline (always worst)

### Future projections

Using IPCC AR6 projections for Central Europe (SSP2-4.5 scenario), we estimated how heatwave sunset temperatures will evolve:

| Decade | Warming vs today | Avg sunset temp (best strategy) | Max sunset temp |
|--------|-----------------|--------------------------------|----------------|
| 2020s | — | 27.4 °C | 31.3 °C |
| 2030s | +1.5 °C | 28.4 °C | 32.3 °C |
| 2040s | +2.0 °C | 28.8 °C | 32.7 °C |
| 2050s | +2.5 °C | 29.1 °C | 33.0 °C |

By the 2050s, even with optimal cooling, the bedroom will average **29 °C at sunset** during heatwaves. This is uncomfortable. The house will need **active cooling** — a heat pump in cooling mode, or at minimum, a ceiling fan — for the 10–15 hottest days of the year.

---

## Practical Recommendations

Based on the data, here is what actually works:

### For normal summer days (max 25–30 °C)
- **Open windows at 06:00**, close when outdoor temp catches up (~10:00–10:30)
- **Keep bedroom shutters in blocking mode** during the day
- **Run Zehnder at Speed 1** overnight for fresh air without noise

### For heatwave days (max > 30 °C)
- **Open windows at 22:00**, close at 06:00
- **Ground floor shutters down 100%** all day
- **Bedroom shutters in blocking mode** all day
- **Run Zehnder at Speed 3** continuously (smart bypass handles the rest — see below)
- **Do not open windows during the day** — even briefly. The solar gain penalty outweighs any ventilation benefit.

### The Zehnder Smart Bypass

Our Zehnder ComfoAir has a **smart bypass** that automatically opens when outdoor temperature exceeds indoor temperature. This changes the heatwave strategy completely:

| Phase | Outdoor vs Indoor | Bypass State | Heat Recovery | What It Does |
|-------|-------------------|--------------|---------------|--------------|
| Night (22:00–06:00) | Outdoor < Indoor | **Closed** | ON | Brings in cool night air, recovers heat from exhaust |
| Morning (06:00–10:00) | Outdoor < Indoor | **Closed** | ON | Pre-cools the house, recovers heat |
| Midday (> 10:00) | Outdoor > Indoor | **Open** | OFF | Brings in fresh air, **without** adding heat |

**Why this matters:** Without the bypass, running Speed 3 on a 35 °C day would add ~0.1–0.5 °C of unwanted heat. With the smart bypass, that penalty drops to **effectively zero**. You get the full CO₂-clearing benefit of Speed 3 (6 ppm/min vs 2 ppm/min) without warming the house.

We simulated this explicitly — same heatwave day, same starting conditions, only the Zehnder strategy changes:

| Zehnder Strategy | Sunset Temperature | CO₂ Clearing Speed |
|------------------|-------------------|-------------------|
| Speed 1 all day | 26.8 °C | Slow (2 ppm/min) |
| Speed 3 all day, no bypass | 26.9 °C (+0.1 °C) | Fast (6 ppm/min) |
| **Speed 3 all day, smart bypass** | **26.8 °C** | **Fast (6 ppm/min)** |

The smart bypass makes Speed 3 a free lunch: **3× faster air clearing at no thermal cost**.

### What does NOT work
- Opening windows during the afternoon "to create a breeze" — outdoor air is hotter than indoor, and solar gain is extreme
- Relying on the Netatmo sensor to judge comfort — it reads 3–5 °C cooler than the bedside sensor during ventilation events
- Night ventilation without shutters — you get fresh air, but the room still hits 35 °C by sunset

---

## The Model

All simulations use a physics-based thermal model calibrated against real sensor data:

- **Thermal mass**: 4.0 MJ/°C for the bedroom (calibrated from bedside sensor data)
- **Ventilation conductance**: 1,000 W/°C for wide-open cross-ventilation (both windows)
- **Solar gain**: 2.2 W per W/m² of irradiance, reduced by shutter state
- **Inter-zone heat transfer**: estimated from adjacent room temperatures

The model is intentionally simple — it runs in milliseconds and can be swept across hundreds of scenarios. Its predictions match reality within **0.5 °C** when fed actual weather data.

---

## What's Next

Future posts in this series will cover:

- **Installing HRV duct sensors** to measure true heat recovery efficiency directly
- **Model Predictive Control (MPC)**: using the thermal model to optimise heat pump scheduling for cost and comfort
- **PV-aware heating:** coupling the thermal model with solar production forecasts
- **Shutter automation:** quantifying how much external shutters actually save, and when to open/close them automatically

---

*This analysis was conducted independently, without involvement or knowledge from Sendom. All data was collected and processed with the homeowner's consent.*
