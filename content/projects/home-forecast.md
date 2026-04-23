---
title: 'home-forecast'
date: 2026-04-03
draft: true
topics: ['energy', 'smart home']
tags: ['machine-learning', 'battery-optimization', 'forecasting', 'home-automation', 'photovoltaic']
tech: ['Python', 'LightGBM', 'SciPy', 'pandas']
description: 'ML-based home energy forecasting with battery dispatch optimization — 6 LightGBM models predict PV, consumption, heat pump load, and spot prices to minimize daily electricity cost via linear programming.'
status: 'in-progress'
---

`~/projects/llm/smart-home/home-forecast` · commit `f69fec2` (2026-04-03)

## Goal

Predict tomorrow's energy profile and optimize battery dispatch to minimize electricity cost. The system forecasts 6 independent streams — solar generation, household consumption, heat pump load, hot water demand, and [spot price][spot] — then solves a [linear program][lp] to schedule when to charge, discharge, or idle.

Designed for a residential property in Poznań (52.4°N, 16.9°E) with rooftop PV, a [Panasonic Aquarea][aquarea] heat pump, and a planned 10 kWh [LFP][lfp] battery.

## Approach

### Forecasting models

Six [LightGBM][lgbm] (gradient boosting) models, each trained on Home Assistant sensor history:

| Model | Key features | Loss function |
|-------|-------------|---------------|
| PV production | Direct/diffuse radiation, cloud cover, solar elevation, temperature, wind | MSE |
| Short-term PV | Wind influence on panel clearance | MSE |
| Consumption | Hour-of-day (cyclical), month, day-of-week, holidays, 6h smoothing | MSE |
| Heat pump | Outdoor temp (15°C threshold), 6h resolution | Asymmetric MSE (3× penalty for underestimation) |
| DHW | 24h smoothing, weighted for peak demand | MSE |
| Spot price | [TGE][tge] day-ahead prices (published ~14:00 CET) | MSE |

Weather data from [Open-Meteo][openmeteo] API with monthly CSV caching. Feature engineering includes cyclical time encoding, [Spencer's declination formula][spencer] for solar position, and clear-sky index normalization.

### Battery optimization

A [linear program][lp] (SciPy `linprog`) minimizes daily import cost minus export revenue:

- **Decision variables**: import, export, charge, discharge per hour
- **Constraints**: energy balance, [SoC][soc] evolution with round-trip efficiency (√ split between charge/discharge), power and capacity limits
- **Configuration**: 10 kWh battery, 5 kW bidirectional, 10–90% usable SoC, 0.8 export coefficient (feed-in tariff discount)

### Model Predictive Control

`controller.py` runs a continuous [MPC][mpc] loop with a rolling 24-hour horizon. Forecasts are cached with ~1-hour TTL. Integrates with Home Assistant for real-time battery control.

### Backtesting

`backtest_mpc.py` replays historical days using ML forecasts against actual spot prices. Compares LP-optimal dispatch vs heuristic strategies vs no-battery baseline.

## Outcome

- 6 trained models (~1.6 MB total), ~4,700 lines of Python, 80 tests
- Test R² scores: spot price ~0.9, heat pump ~0.7, PV ~0.5
- ROI tools: monthly cost breakdown, capacity sweep, hardware-specific payback analysis
- Battery ROI modeling for investment decision

[spot]: https://en.wikipedia.org/wiki/Electricity_market#Spot_market
[lp]: https://en.wikipedia.org/wiki/Linear_programming
[aquarea]: https://www.panasonic.com/global/hvac/aquarea.html
[lfp]: https://en.wikipedia.org/wiki/Lithium_iron_phosphate_battery
[lgbm]: https://en.wikipedia.org/wiki/LightGBM
[tge]: https://en.wikipedia.org/wiki/Towarowa_Gie%C5%82da_Energii
[openmeteo]: https://open-meteo.com/
[spencer]: https://en.wikipedia.org/wiki/Position_of_the_Sun#Declination_of_the_Sun
[soc]: https://en.wikipedia.org/wiki/State_of_charge
[mpc]: https://en.wikipedia.org/wiki/Model_predictive_control
