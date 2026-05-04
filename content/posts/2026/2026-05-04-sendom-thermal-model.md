---
title: "Reverse-Engineering the Thermal Performance of a sendom.pl House"
date: 2026-05-04
tags: ["energy", "thermal-modeling", "system-modeling", "hvac", "julia", "home-assistant", "sendom"]
description: "How we built a calibrated six-zone thermal model of a sendom.pl prefab house using Home Assistant sensor data, and what it revealed about insulation quality and HRV efficiency."
topics: ["energy", "home-automation"]
math: true
---

This is the first post in a series reviewing the thermal performance of a <a href="https://sendom.pl" target="_blank">Sendom</a> prefabricated house located near Poznań. Instead of relying on the builder's specifications or energy certificates alone, we took a different approach: **we instrumented the house with sensors, recorded months of real data, and built a physics-based thermal model calibrated against actual indoor temperatures.**

The goal was to answer questions that no datasheet can:

- How well is the house actually insulated?
- Is the Heat Recovery Ventilation (HRV) delivering the efficiency it promises?
- Which rooms lose heat fastest?
- How much energy does the house really need to stay warm?

## The House

The building is a two-storey prefabricated house from <a href="https://sendom.pl" target="_blank">Sendom</a>, a Polish manufacturer of modular timber-frame homes. It has six thermal zones: a large open-plan living room with kitchen on the ground floor, three smaller rooms (also ground floor), and two rooms plus a bathroom upstairs. Total floor area is approximately **109 m²**.

The heating system is a heat pump with underfloor water distribution. Ventilation is mechanical with heat recovery (HRV). The house has external shutters on most windows, which turn out to matter more than expected for thermal modelling. This precise house has external shutters on all ground floor windows.

## Sensors and Data Collection

### What We Measured

All data flows into **Home Assistant**, an open-source home automation platform. From there, we extract hourly time series for model calibration. Here is what we actually use:

| Measurement | Source | Role in Model |
|-------------|--------|---------------|
| Indoor temperature (6 rooms) | Zigbee temperature sensors | Target variables for calibration |
| Outdoor temperature | Heat pump outdoor unit + Open-Meteo API | Boundary condition |
| Solar direct / diffuse radiation | Open-Meteo API | Solar gain forcing |
| Wind speed | Open-Meteo API | Infiltration modifier |
| Heat pump power | HA energy sensor (<a href="https://github.com/heishamon/HeishaMon" target="_blank">HeishaMon</a>) | Internal heat source |
| Water temperature | HA sensor | Underfloor heating input |
| Window/door states | HA binary sensors | Infiltration boost (3× when open) |
| Shutter positions | HA cover entities | Solar gain blocking |

The indoor sensors are cheap Zigbee devices (Aqara, Sonoff, Tuya — whatever was on hand). They are not calibrated against a reference thermometer, but since we care about temperature *differences* between rooms and relative changes over time, absolute accuracy matters less than consistency. The model is fitted to the sensors we have, not to some theoretical ideal.

### Data Gaps and Preprocessing

Real sensor data is messy. Batteries die. Zigbee mesh drops packets. Someone moves a sensor. We preprocess the data before feeding it to the model:

- **Forward-fill gaps** up to 3 hours. Short gaps are harmless; longer gaps break the calibration.
- **Synchronise to hourly intervals.** The model runs on 1-hour steps, so we resample everything.
- **Filter to periods where all six room sensors are active.** Before February 2026, some rooms lacked sensors. The calibration uses only complete data.
- **Derive internal gains.** We estimate heat from occupants, appliances, and lights from electricity consumption and simple occupancy heuristics.

The final dataset spans several weeks of winter and spring data, with contiguous runs of complete observations. We use the longest contiguous run for calibration and the second-longest for validation.

## Building the Thermal Model

### From Single-Zone to Six-Zone

We started with a simpler single-zone model that treated the whole house as one big thermal mass. It worked — total heat loss coefficient was around **57 W/°C**, thermal mass around **8.4 kWh/°C** — but it could not answer per-room questions. In practical terms, 57 W/°C means the house loses 57 watts of heat for every degree of temperature difference between indoors and outdoors. At a typical winter delta of 20 °C (20 °C inside, 0 °C outside), that is roughly 1.1 kW of continuous heat loss just to maintain temperature. A cold bedroom and a warm living room look the same to a single-zone model.

The multi-zone model treats each room as a separate thermal node connected to its neighbours through walls and floors. The governing equation for each zone is an energy balance ODE:

$$
C_i \frac{dT_i}{dt} = Q_{\text{ext}} + Q_{\text{adj}} + Q_{\text{solar}} + Q_{\text{vent}} + Q_{\text{uf}} + Q_{\text{ground}} + Q_{\text{int}}
$$

Where:

- \(C_i\) = thermal mass (how much energy it takes to change the room's temperature)
- \(Q_{\text{ext}}\) = heat loss through external walls, roof, and windows
- \(Q_{\text{adj}}\) = heat exchange with adjacent rooms through shared walls
- \(Q_{\text{solar}}\) = solar gains through windows (reduced when shutters are closed)
- \(Q_{\text{vent}}\) = ventilation and infiltration losses (reduced by HRV recovery)
- \(Q_{\text{uf}}\) = underfloor heating input
- \(Q_{\text{ground}}\) = ground coupling (ground-floor rooms only)
- \(Q_{\text{int}}\) = internal gains from people, appliances, and lights

### Model Topology

The house is modelled as a graph where edges represent thermal conductance. Not all rooms touch each other directly, so we use a qualitative adjacency matrix based on the floor plan:

| Zone | Direct neighbours | Weight |
|------|-------------------|--------|
| Living room | Ground floor bedroom 1 | 1.0 (shared wall) |
| Living room | Ground floor bedroom 2 | 0.5 (indirect) |
| Living room | Upstairs rooms | 0.2–0.3 (through ceiling/floor) |
| Master bedroom | Bathroom | 1.0 (adjacent) |
| Bathroom | First floor bedroom | 1.0 (adjacent) |

These weights are relative. During calibration, a single scaling factor (`U_adj_scale`) is fitted to convert them into absolute conductances in W/°C.

### The Calibration Problem

We have 32 unknown parameters:

| Parameter | Count | Unit | What It Means |
|-----------|-------|------|---------------|
| \(C\) (thermal mass) | 6 | MJ/°C | How "heavy" each room is thermally |
| \(U_{\text{ext}}\) (external loss) | 6 | W/°C | Heat leak through envelope per room |
| \(U_{\text{adj}}\) scale | 1 | — | Multiplier for adjacency matrix |
| \(g_{\text{direct}}\) (solar gain) | 6 | W per W/m² | How much solar radiation enters each room |
| \(\alpha_{\text{uf}}\) (UFH coupling) | 6 | W/°C | How effectively underfloor heating warms each room |
| \(U_{\text{vent}}\) (ventilation) | 6 | W/°C | Air-exchange heat loss per room |
| HRV efficiency | 1 | 0–1 | Fraction of ventilation heat recovered |

**Total: 32 parameters.**

We fit them by minimising the root-mean-square error (RMSE) between predicted and measured indoor temperatures across all six rooms. The optimiser is Nelder-Mead, a derivative-free method that handles the non-linearities and parameter interactions reasonably well.

### Calibration vs. Validation

| Metric | Value |
|--------|-------|
| Calibration RMSE | **0.597 °C** |
| Validation RMSE | **0.841 °C** |
| Improvement over default params | ~35% |

A sub-degree RMSE across six rooms is good. It means the model captures the real thermal behaviour well enough to trust its parameter estimates.

### Calibrated Parameters (Selected)

| Zone | \(C\) (MJ/°C) | \(U_{\text{ext}}\) (W/°C) | \(\alpha_{\text{uf}}\) (W/°C) | \(U_{\text{vent}}\) (W/°C) |
|------|-------------|------------------------|---------------------------|--------------------------|
| Living room | 30.98 | 13.32 | 8.24 | 11.78 |
| Master bedroom | 8.73 | 3.67 | 15.48 | 6.86 |
| Bathroom | 4.45 | 0.53 | 29.96 | 2.42 |
| Ground floor bedroom 1 | 7.50 | 4.00 | 6.97 | 5.03 |
| Ground floor bedroom 2 | 7.30 | 3.82 | 12.69 | 5.32 |
| First floor bedroom | 5.76 | 5.51 | 1.12 | 4.28 |

A few things stand out immediately:

- The **living room** has 4× the thermal mass of any bedroom. This makes sense: it is open-plan, connected to the kitchen, and has more furniture and masonry exposed.
- The **bathroom** has very low external heat loss (0.53 W/°C). It is mostly an internal room, though it does have a small external wall. Note: there is no temperature sensor in the ground-floor bathroom; the "Bathroom" zone in the model refers to the first-floor bathroom.
- **Underfloor heating coupling** varies wildly: the bathroom is very responsive (\(\alpha_{\text{uf}} = 30\) W/°C), while the first floor bedroom is barely coupled (\(\alpha_{\text{uf}} = 1.1\) W/°C). This is useful diagnostic information — it suggests the UFH loop in that room may be partially closed or have a long pipe run.

---

## How We Calculated HRV Efficiency

### The Fitted Value

The calibration converged on an HRV efficiency of **82.8%**. This means the ventilation system recovers roughly 83% of the heat from outgoing stale air and transfers it to incoming fresh air.

This is not a direct measurement. We did not put temperature probes on the supply and exhaust ducts. The 82.8% is a **model parameter** that the optimiser settled on because it made the simulated indoor temperatures match reality best.

### Why This Number Is Plausible

Modern HRV units are typically rated at **80–95% sensible heat recovery efficiency**. An fitted value of 82.8% sits comfortably in the middle of that range. If the optimiser had returned 40% or 99%, we would be suspicious. But 83% is exactly what you would expect from a well-maintained unit in a modern house.

### The Identifiability Problem — Why We Cannot Be Certain

Here is the subtle issue: **HRV efficiency and ventilation conductance (\(U_{\text{vent}}\)) are partially correlated.** The model cannot perfectly distinguish between:

- High airflow + high HRV efficiency, or
- Low airflow + low HRV efficiency

Both produce similar effective heat loss because the governing term is:

$$
Q_{\text{vent, effective}} = U_{\text{vent}} \times (1 - \text{hrv}_{\text{efficiency}}) \times (T_{\text{out}} - T_{\text{room}})
$$

The calibration only constrains the **product** \(U_{\text{vent}} \times (1 - \text{hrv}_{\text{efficiency}})\), not the individual factors. If the true HRV efficiency were 90%, the optimiser could compensate by increasing \(U_{\text{vent}}\). If it were 70%, it would decrease \(U_{\text{vent}}\).

### Sensitivity Analysis

To quantify the uncertainty, we re-ran the annual heating demand estimate with different HRV efficiency assumptions while keeping the fitted \(U_{\text{vent}}\) values:

| Assumed HRV Efficiency | Effective Vent. Loss | Annual Demand | Rating |
|------------------------|----------------------|---------------|--------|
| 70% | 10.7 W/°C | 35.6 kWh/m²/yr | Low-energy building |
| **82.8% (fitted)** | **6.2 W/°C** | **32.4** | **Low-energy building** |
| 92% | 2.9 W/°C | 30.1 kWh/m²/yr | Low-energy building |

Even with a ±10 percentage point swing in HRV efficiency, the house stays in the same performance category. The HRV is unequivocally doing important work — the exact percentage is a secondary refinement.

### How to Validate It Properly

For a definitive answer, we would need one of these:

| Method | Effort | Confidence |
|--------|--------|------------|
| Duct temperature sensors (supply vs. exhaust) | Low (2 additional sensors) | **High** — measures true efficiency directly |
| Airflow measurement (anemometer on ducts) | Medium | **High** — fixes \(U_{\text{vent}}\), leaving only HRV efficiency to fit |
| Co-heating test (electric heater, HRV off) | High | Medium — isolates envelope from ventilation |
| Manufacturer datasheet comparison | Trivial | Low — rated vs. real-world efficiency differs due to installation quality, filter state, and frost protection cycles |

We plan to integrate the HRV with Home Assistant in a future post, adding supply and exhaust duct sensors for direct measurement.

---

## Results: Insulation Factor and Energy Efficiency

### Overall Heat Loss

| Component | Conductance | Share of Total |
|-----------|-------------|----------------|
| External envelope (walls, roof, windows) | 30.84 W/°C | 67% |
| Ground coupling | 9.00 W/°C | 20% |
| Ventilation (after HRV recovery) | 6.15 W/°C | 13% |
| **Total HLC** | **45.99 W/°C** | **100%** |

### Specific Heat Loss (Normalised by Floor Area)

| Metric | Value | Benchmark |
|--------|-------|-----------|
| Envelope only | 0.366 W/°C/m² | Modern building code |
| Total (incl. ventilation) | 0.422 W/°C/m² | Modern building code |

For context: a Passive House targets ≤0.15 W/°C/m². An older uninsulated house in Poland might be 0.8–1.5. This house sits comfortably in the "modern standard" band — good but not exceptional.

### Thermal Time Constant

The total thermal mass is **64.7 MJ/°C** (~18 kWh/°C). Dividing by the total heat loss coefficient gives a **time constant of 391 hours** — about **16 days**.

In physical terms, the time constant is the time it would take for the indoor temperature to drop by roughly 63% of the initial temperature difference if heating were suddenly turned off and no internal gains were present. It is a measure of thermal inertia: how long the building can maintain its temperature without active heating.

This is very high. It means that if you turned the heating off completely in mid-winter, the house would take more than two weeks to cool down to outdoor temperature. The thermal mass "rides through" short cold snaps and heating interruptions effortlessly. This is a genuine performance advantage of the <a href="https://sendom.pl" target="_blank">Sendom</a> construction — the timber frame with its insulation and internal mass creates a thermally stable shell.

### Per-Room Ranking

Sorted by specific heat loss (lower is better):

| Rank | Room | Spec. Loss (W/°C/m²) | Notes |
|------|------|----------------------|-------|
| 1 | Bathroom | 0.118 | Small external wall |
| 2 | Bedroom | 0.323 | Good envelope performance |
| 3 | Living room | 0.407 | Large area dilutes the losses |
| 4 | First floor bedroom | 0.520 | Moderate |
| 5 | Ground floor bedroom 2 | 0.561 | Higher than expected — check windows/doors |
| 6 | Ground floor bedroom 1 | 0.572 | Worst performer — potential upgrade target |

The two smallest ground floor bedrooms have the highest specific heat loss. This is partly because small rooms have high surface-to-volume ratios, but these are also corner rooms, which increases exposure. Both rooms are used as offices, and windows are opened frequently to reduce CO₂ levels, which may contribute to the higher measured heat loss.

### Estimated Annual Heating Demand

Using **3,200 °C·days/year** (a typical value for the Poznań region, base 18°C):

$$
E_{\text{annual}} = \text{HLC} \times \text{HDD} \times 24 \,/\, 1000 = 3{,}532 \text{ kWh/year}
$$

Normalised by area: **32.4 kWh/m²/year**.

This places the house in the **"low-energy building"** category — better than typical Polish new build (~60–80 kWh/m²/yr), but not quite Passive House (≤15 kWh/m²/yr).

### Overall Score

We compute a composite score from three factors:

| Factor | Score | Weight |
|--------|-------|--------|
| Specific heat loss | 71.9 / 100 | 50% |
| Thermal time constant | 100.0 / 100 | 25% |
| Annual heating demand | 83.8 / 100 | 25% |
| **Overall insulation score** | **81.9 / 100** | — |

**Rating: Excellent.** The house is genuinely energy-efficient, with the HRV and thermal mass being the standout features.

---

## Why Julia? (And Why It Was Sometimes Frustrating)

This entire model is written in **Julia**, a language designed for scientific computing. Here is what worked and what did not.

### What Was Good

**DifferentialEquations.jl is best-in-class.** The ODE solver handles the stiff thermal system effortlessly. Switching solvers (Tsit5, Rosenbrock23, etc.) is one line of code. Event handling, interpolation, and adjoint sensitivity analysis are all built in — things that would require significant boilerplate in Python or C++.

**The optimisation ecosystem is mature.** We use `Optimization.jl` with `OptimizationOptimJL` for the Nelder-Mead calibration. JuMP + Ipopt is available if we ever need constrained nonlinear programming. The syntax is clean and mathematical.

**Performance is excellent once compiled.** A single simulation of the six-zone model over two weeks runs in milliseconds. The calibration loop (hundreds of simulations) finishes in minutes, not hours.

**Multiple dispatch makes the code expressive.** Writing `simulate(params, forcing, T0, tspan)` with different parameter types or solver options feels natural. The code reads like math.

### What Was Not Good

**Time-to-first-plot (TTFP) is real.** On a cold start, loading DifferentialEquations.jl + Plots.jl + DataFrames.jl takes 30–45 seconds. For a script you run once a day, this is annoying. For interactive exploration, it is painful. We mitigate it by keeping a long-running Julia REPL, but that is not always practical.

**Binary deployment is hard.** Unlike Go or Rust, Julia does not compile to a single static binary easily. `PackageCompiler.jl` exists but is finicky. Sharing the model with someone who does not have Julia installed is essentially impossible without a Docker container.

**The package ecosystem is smaller.** Need a specific Home Assistant client library? Probably does not exist in Julia. We extract data via Python scripts and feed CSVs to Julia. The interoperability (PyCall.jl) works but adds friction.

**Error messages can be opaque.** When a type-stable function suddenly becomes type-unstable because you changed one parameter, the performance cliff is steep and the diagnostic tools (`@code_warntype`) require expertise.

### The Verdict

Julia was the **right choice for the model itself**. The combination of DifferentialEquations.jl, Optimisation.jl, and native performance is hard to beat for this workload. But for data ingestion, Home Assistant integration, and deployment, Python or Go would have been smoother. If we were starting over, we might keep Julia for the physics core and wrap it in a Python/Go service for everything else.

---

## Conclusions and What's Next

### What We Learned

1. **The house is well-insulated.** Specific heat loss of 0.42 W/°C/m² and 32.4 kWh/m²/year annual demand place it in the low-energy category. The <a href="https://sendom.pl" target="_blank">Sendom</a> construction delivers on its promises.

2. **The HRV is doing critical work.** Without heat recovery, ventilation would account for 44% of heat loss. With recovery, it drops to 13%. The fitted efficiency of 83% is plausible but not directly validated yet.

3. **Thermal mass is the hidden superpower.** A 16-day time constant means the house is extraordinarily stable. Short heating gaps, cold snaps, or load-shifting experiments are all viable because the building inertia smooths everything out.

4. **Two rooms underperform.** The two smaller ground floor bedrooms have 40% higher specific heat loss than the living room.

5. **Underfloor heating is uneven.** The bathroom responds 27× faster to water temperature changes than the first floor bedroom. However, the first-floor bathroom temperature data is not very reliable — a clothes dryer is located there and its heat output affects the sensor. We are still missing dryer power usage data because the power meter is failing. This makes it hard to separate UFH response from dryer interference.

### Limitations

- The HRV efficiency is a fitted parameter, not a measurement. See Section 4 for the identifiability problem.
- Ground coupling values are defaults, not calibrated.
- Internal gains are estimates, not measured.
- Annual demand uses a fixed HDD value; real weather varies year to year.
- The model is linear — no radiation heat transfer, no moisture effects, no wind-pressure-dependent infiltration.

### Next in the Series

Future posts will cover:

- **Installing duct sensors** to measure true HRV efficiency
- **Model Predictive Control (MPC):** using the thermal model to optimise heat pump scheduling for cost and comfort
- **PV-aware heating:** coupling the thermal model with solar production forecasts
- **Shutter optimisation:** quantifying how much energy external shutters actually save
- **Hydraulic balancing:** using the model to diagnose underfloor heating unevenness

---

*This analysis was conducted independently, without involvement or knowledge from Sendom. It is the result of a private initiative to measure as much as possible using the homeowner's own sensors and to analyse the collected data. All data was collected and processed with the homeowner's consent.*
