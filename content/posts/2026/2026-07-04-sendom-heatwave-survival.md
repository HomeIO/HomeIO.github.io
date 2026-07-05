---
title: "How to Survive a Heatwave in a Sendom House: What 40 °C Taught Us"
date: 2026-07-04
draft: false
tags: ["energy", "cooling", "hvac", "thermal-modeling", "home-assistant", "sendom", "climate-change"]
description: "During the late-June 2026 heatwave we let the sensors run and treated a 40 °C weekend as a thermal stress test. The results: keeping cool cost less than a light bulb, the sun paid for most of it, and the cheapest fix for the hot bedroom isn't an air conditioner."
topics: ["energy", "home-automation"]
math: true
---

In the [thermal model post](/posts/2026/2026-05-04-sendom-thermal-model/) we reverse-engineered how a <a href="https://sendomsmart.pl/" target="_blank">Sendom</a> prefab house loses heat in winter. In the [cooling and ventilation post](/posts/2026/2026-05-25-sendom-cooling-ventilation/) we looked at keeping it cool with nothing but windows and shutters. Then, in the last days of June 2026, the weather ran the experiment we couldn't: a week-long heatwave peaking near **40 °C**, the hottest days ever recorded at this house.

We did what any sensor-obsessed household would do — kept the data flowing and treated the whole thing as a **thermal stress test**. This post is what we learned: what surviving a heatwave actually costs, where the house's armor is strong, where it's thin, and what climate change does to the yearly energy balance of a well-insulated timber-frame home.

Spoiler: the house passed. The bill for the entire record weekend was about **two złoty**.

---

## The Stress Test: 29 Hours at (Nearly) 40 °C

From Saturday noon to Sunday 17:00 the outdoor air swung between 25 °C (a tropical night — it never dropped below the indoor setpoint) and 39 °C in the shade. The single living-room air conditioner — a Fujitsu 2.5 kW (thermal) inverter split, set to a 24 °C target with the louvres on swing and the fan on automatic — pinned the open-plan zone to a band of **23.4–24.1 °C**, a 0.7 °C wobble against a 15 °C outdoor swing. It was rarely working hard: for roughly a fifth of the weekend it was idle, coasting with no cooling demand at all — moments when even the unit's minimum output would have been more than the room needed. The rest of the time it modulated well below full power.

![Heatwave weekend timeline: outdoor vs indoor temperatures, AC power, solar irradiance](/img/posts/sendom-heatwave/102_weekend_timeline.png)

The numbers for those 29 hours:

| Metric | Value |
|--------|-------|
| AC electricity used | **3.84 kWh** (avg ≈ 130 W — a fridge) |
| Heat removed (at EER 3.4) | ≈ 12.9 kWh |
| Living room held at | 23.4–24.1 °C |
| Uncooled master bedroom drifted to | **29.8 °C** |
| Effective electricity per °C·h of "heat pressure" | 14.4 Wh |

Two details worth pausing on. First, the *average* electrical draw needed to hold back a 40 °C afternoon was about what a refrigerator uses. Second, the uncooled bedroom upstairs is the honest counterfactual: without cooling, that's where the whole house would drift. More on that room later — it's the main character of the second half of this post.

(A sensor lesson en passant: the outdoor Netatmo module read **42 °C** in the afternoon sun and **19 °C** during the clear night — biased in both directions by radiation. All physics below uses radiation-shielded air temperature from the Open-Meteo archive; the Netatmo is shown on the chart for honesty.)

---

## The AC as a Measuring Instrument

Here is the trick that turns a heatwave into science: when a room's temperature is held constant, **every watt the AC removes must equal the heat leaking in**. The AC becomes a heat-flow meter for the building envelope — the summer mirror image of a co-heating test, run by the weather for free.

Fitting the hourly steady-state balance over the weekend:

$$Q_{removed} = UA \cdot (T_{out} - T_{room}) + gA \cdot GHI + Q_{internal}$$

gives **R² = 0.94** and three physically meaningful numbers:

- **UA ≈ 40 W/°C** — the cooled zone leaks ~40 W of heat inward per degree of outdoor excess,
- **gA ≈ 0.13 W per W/m²** of horizontal solar irradiance — the effective solar aperture with shutters managed,
- **Q_internal ≈ 30–80 W** — background gains from appliances on standby and the ventilation fan.

Worth stating the test conditions plainly: from Saturday 10:00 to about Sunday 18:00 the house was empty. No people, no cooking, appliances on standby only, all shutters closed, and the mechanical ventilation running at its ~40 % speed setting. So the fitted Q_internal here is *not* metabolic heat from occupants — it's the floor of gains the house produces even with nobody home. With people, cooking, and screens on, this term would be larger.

![Hourly heat budget: conduction, solar and internal gains vs heat actually removed by the AC](/img/posts/sendom-heatwave/102_energy_budget.png)

The stacked bars are the *fitted* heat inflows; the black step is what the AC *actually* removed. They track each other hour by hour.

### Three Independent Estimates, One House

We now have the envelope measured three different ways, in two different seasons, with two different machines:

| Method | Season | Scope | Result |
|--------|--------|-------|--------|
| Six-zone model calibration ([earlier post](/posts/2026/2026-05-04-sendom-thermal-model/)) | winter | whole house | ~57 W/°C |
| Heat-pump degree-day regression | winter | whole house | **69 W/°C** (R² = 0.90) |
| AC steady-state balance (this heatwave) | summer | cooled zone | **40 W/°C** |

The degree-day figure runs a bit above the calibrated model because a regression slope absorbs ventilation behavior and solar variation that the model handles explicitly. But the interesting consistency check is the third row: the cooled zone's 40 W/°C is ~60 % of the whole house — and our hot-day data shows the AC's cold *does* spread that far (the kitchen and both ground-floor rooms barely warm up on heatwave days, see below). That spread had help: a ceiling fan ran constantly at half speed throughout the test, stirring the open-plan air so the single living-room unit reached the kitchen and adjacent rooms. Three methods, in two seasons, with two different machines, landing within the same range.

---

## What a Degree of Comfort Costs

With the response model in hand, we can price the eternal thermostat argument. Replaying the model over the real heatwave weather (June 21–30), each 1 °C lower setpoint costs about **0.18 kWh ≈ 0.09 PLN per day** — rising to 0.14 PLN/day on the 40 °C day.

![Cost of holding each setpoint through the heatwave](/img/posts/sendom-heatwave/106_setpoint_cost.png)

Holding 24 °C instead of 26 °C through an entire heatwave month costs roughly **5 PLN**. In a well-insulated house like this one, the fear of the AC bill simply doesn't hold up. Set the thermostat where you sleep well.

There's a second lesson in *how* you run it. Holding a comfortable setpoint continuously, with the fan on automatic, turned out cheaper than the instinctive habit of leaving the AC off, letting the room climb, then blasting it cold. A steady 24 °C lets the inverter idle and modulate at low power against a small ΔT; a deep cool-down after the room has soaked up heat forces the compressor to run flat-out against a much larger gradient, and it has to pull back out the thermal mass the walls and furniture just absorbed. Cheaper to never let the heat in than to chase it out.

---

## The Sun Pays for Its Own Damage

Cooling demand has a property winter heating can only dream of: it peaks exactly when the roof produces the most. Our PV production sensor happened to be down, but the grid meter tells the story — whenever the house is exporting, every load inside runs on sunshine.

Treating the AC as the marginal load: **72 % of all heatwave air-conditioning energy ran while the house was exporting**.

![AC energy split into sun-paid vs imported, per heatwave day](/img/posts/sendom-heatwave/109_ac_self_vs_import.png)

Priced honestly (imports at spot + distribution fees, self-consumption at the foregone export value), the whole seven-day heatwave cost about **12 PLN effective** instead of 19 naive. The point isn't to over-cool for the sake of it — the AC only ever runs as hard as comfort needs, and the aim is to keep the room comfortable, not to chase the export surplus. Storing that midday surplus for the evening — in a home battery rather than the walls — is a lever worth exploring later, but that's a topic for another post.

---

## The Weak Spot: Upstairs at Night

Now for the room the AC doesn't reach. Plotting each room's afternoon maximum against the outdoor maximum across all seven heatwave days gives each room a "heat penetration slope" — 0 means defended, 1 means you're living outdoors:

| Room | Slope | Verdict |
|------|-------|---------|
| Living room (AC) | ≈ 0 | defended |
| Kitchen | ≈ 0 | defended (AC spillover) |
| Ground-floor rooms | ≈ 0 | defended |
| **Upstairs bedrooms** | **+0.32…+0.33** | a third of every extra degree gets in |

The upstairs bedrooms — directly under the roof, remember the [16-day time constant](/posts/2026/2026-05-04-sendom-thermal-model/) doesn't apply to the lightweight attic envelope — reached **28–30 °C** on the worst days. And they did so with their shutters fully closed the whole time: the first-floor bedroom shutters stayed down throughout. So this heat isn't coming through the glass — the windows are already defended. It's coming down through the roof, which is why shutters (item 2 below) buy the ground floor a lot and the top floor comparatively little.

One caveat that's also part of the experiment: the house was empty over the Saturday and Sunday nights, so nobody was there to open the bedroom windows and flush it with cool night air. Occupied, those rooms would have run cooler — night ventilation is exactly the free lever explored below. Leaving it unused was deliberate: it shows the passive worst case.

One mercy: it was *dry* heat. Dew points stayed mostly below the "muggy" threshold (18 °C) even in the hot bedroom. A 29 °C bedroom at a 16 °C dew point is a place where a fan genuinely works, because sweat still evaporates.

---

## The Fix: Free Cooling First, Hardware Second

Does the upstairs need its own AC, then? The bedroom's own physics answers it — inverting its free-float temperature trace gives the cooling power required to hold 25 °C:

- peak demand: **~410 W thermal** (the smallest wall split sold, 1.5 kW, is 3–4× oversized),
- running cost: **~0.40 PLN/day** during a heatwave.

Cheap. But before spending anything, look at what the *night* offers. We simulated a windows-managed night (open whenever outdoor air is cooler, never ventilating below a 20 °C comfort floor, using the RC constants calibrated in the window-opening experiments):

![Observed vs achievable bedroom morning temperatures, June nights](/img/posts/sendom-heatwave/108_night_dumbbells.png)

The bedroom wakes up on average **5.4 °C warmer than the night air could have made it**. Over 18 June nights, that's ~32 kWh of AC-equivalent cooling left on the table — an order of magnitude more than the hypothetical bedroom AC would ever need to do.

The priority order writes itself:

1. **Ventilation discipline** (or better, automation — a window actuator driven by the indoor/outdoor differential) — free;
2. **Shutters down before the sun hits** — free, and the whole-house solar aperture we measured (0.13 W per W/m²) is low *because* of them;
3. **A small bedroom AC** — only if 1 and 2 still leave the room above your sleep threshold; any unit sold today is oversized for the job.

---

## Zooming Out: The House's Full Thermal Signature

The heatwave completed something we couldn't draw before: the *right half* of the house's energy signature. Building scientists fingerprint a building as a V-shaped curve — energy per day against outdoor temperature. We had two winters of the heating wing from the heat pump; now the AC has drawn the cooling wing:

![Energy signature: heating and cooling electricity vs outdoor temperature](/img/posts/sendom-heatwave/111_energy_signature.png)

| Parameter | Value |
|-----------|-------|
| Heating wing | **1.07 kWh/day per °C** below a 7 °C daily mean (R² = 0.94) |
| Cooling wing | **0.27 kWh/day per °C** above a 31 °C daily max (R² = 0.81) |
| Free-running band | daily mean 7 °C → daily max 31 °C: **zero climate-control energy** |

The asymmetry is the story: cold costs this house four times more per degree than heat does. Partly physics (a winter ΔT of 25 °C vs a summer ΔT of 10 °C), partly the machines (both are heat pumps moving heat against a gradient — but the summer gradient is small), and partly the envelope doing exactly what a Nordic-style timber frame is designed to do.

### What Climate Change Does to This Curve

Replaying the last twelve months of real weather shifted by the IPCC AR6 Central-Europe projections (SSP2-4.5: +1.5 °C by the 2030s, +2.5 °C by the 2050s):

![Projected heating vs cooling electricity per year under IPCC warming scenarios](/img/posts/sendom-heatwave/111_climate_shift.png)

By the 2050s this house trades **−281 kWh/yr of heating for +42 kWh/yr of cooling — a net −26 %** in temperature-driven electricity. For a well-insulated, heat-pump-heated, PV-topped house in Poland, warming is (narrowly, financially, and with all due discomfort about the wider picture) a net energy *saving* — because the growing bill is the one the sun pays 72 % of, and the shrinking bill is the one it doesn't.

One honest caveat: a mean-shift scenario moves the average but not the *frequency of heatwaves*, and AR6 is explicit that extremes grow faster than means. Treat the cooling bars as lower bounds. If another heatwave this severe arrives, we'll revisit and update this post with the fresh data.

---

## The Survival Checklist

Everything above, compressed to what to actually do when the forecast says 38 °C:

1. **Night before**: ventilate the bedrooms until the room hits ~20 °C or the outdoor air stops being cooler. This is worth more than any machine you can buy for the room.
2. **Morning, before the sun hits the glass**: shutters down on the sun-facing sides. Windows closed the moment outdoor passes indoor.
3. **Midday**: let the AC hold the ground floor; set it where you're comfortable — the difference between 24 °C and 26 °C is pocket change. If you have PV, this is also when the cooling is free.
4. **Evening**: resist opening up at the first "it feels cooler now" — outdoor air is usually still warmer than your walls until well after sunset. The sensors say the crossover at this house is typically around 21:30–22:00.
5. **Don't fear the bill.** Our record weekend: 3.84 kWh. The house's insulation does the heavy lifting; the AC just settles the remainder.

---

*Methods, for the curious: all analysis runs on Home Assistant sensor history (Zigbee plugs and thermometers, Netatmo, HeishaMon) plus Open-Meteo archive weather, processed in R. Heat removed by the AC assumes EER 3.4 (EN 14511 A35/A27 rating point); every purely electrical figure is assumption-free. The steady-state envelope fit uses only hours where the room temperature held within 0.4 °C. Winter conductance comes from a degree-day regression on the heat pump's reported thermal output — no efficiency assumptions there either.*
