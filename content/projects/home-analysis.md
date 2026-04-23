---
title: 'home-analysis'
date: 2026-04-16
draft: true
topics: ['energy', 'smart home']
tags: ['data-analysis', 'home-automation', 'heat-pump', 'photovoltaic', 'visualization']
tech: ['R', 'tidyverse', 'ggplot2']
description: '80 R analysis scripts generating 230 charts from 2+ years of Home Assistant sensor data — heat pump efficiency, PV performance, thermal modeling, occupancy detection, and grid power quality.'
status: 'in-progress'
---

`~/projects/llm/smart-home/home-analysis` · commit `19a53f6` (2026-04-16)

## Goal

Extract actionable insights from 2+ years of granular [Home Assistant][ha] sensor telemetry. Not a dashboard — a post-hoc analysis suite that digs into heat pump performance, solar generation patterns, thermal behavior, and grid power quality.

## Approach

80 numbered R scripts, each focused on a specific analysis. Each script reads Home Assistant CSV exports, processes the data with [tidyverse][tidyverse], and generates 1–3 [ggplot2][ggplot2] visualizations. A Makefile orchestrates execution with dependency tracking.

### Energy metrics

- **Heat pump**: [COP][cop] vs outdoor temperature curves, compressor cycling analysis, defrost detection, heating curve audit, seasonal response
- **Photovoltaic**: self-consumption ratio, clipping losses, degradation tracking, rain correlation, [clear-sky index][csi]
- **Battery feasibility**: payback period modeling for 10 kWh [LFP][lfp] scenarios, temperature effects on performance
- **Grid**: peak vs average power, import/export duration curves, voltage quality, three-phase load balance, wiring impedance mapping, reactive power and power factor

### Thermal analysis

- Room-by-room thermal response to outdoor temperature changes
- [DHW][dhw] (domestic hot water) optimization: tank standby losses, reheat cycles
- Cooling projections under climate scenarios (+1.4°C vs +2.7°C global warming)
- Energy savings from 1–3°C setpoint reductions
- Wind chill and atmospheric pressure front correlation
- Mold risk assessment from humidity/temperature data

### Occupancy and comfort

- CO₂-based occupancy detection: work-from-home patterns, office utilization rates
- Thermal comfort index, sleep quality vs humidity correlation
- Meal detection from oven/hob power signatures
- Kettle usage patterns as daily rhythm proxy
- Air quality and ventilation analysis ([Zehnder][zehnder] HRV speed comparison)

### Self-sufficiency

- Daily and seasonal self-sufficiency calendars
- Load shifting potential analysis
- Price-weather nexus: spot price vs generation correlation

## Outcome

- 80 analysis scripts, ~23,500 lines of R
- 230 generated charts across all analyses
- Data from 40+ sensors: [Panasonic heat pump][aquarea] integration, Zigbee/ZHA devices, [Hoymiles][hoymiles] PV gateway, grid meters

[ha]: https://en.wikipedia.org/wiki/Home_Assistant
[tidyverse]: https://en.wikipedia.org/wiki/Tidyverse
[ggplot2]: https://en.wikipedia.org/wiki/Ggplot2
[cop]: https://en.wikipedia.org/wiki/Coefficient_of_performance
[csi]: https://en.wikipedia.org/wiki/Clear-sky_index
[lfp]: https://en.wikipedia.org/wiki/Lithium_iron_phosphate_battery
[dhw]: https://en.wikipedia.org/wiki/Domestic_hot_water
[zehnder]: https://en.wikipedia.org/wiki/Zehnder_Group
[aquarea]: https://www.panasonic.com/global/hvac/aquarea.html
[hoymiles]: https://www.hoymiles.com/
