---
title: 'energy-market-sim'
date: 2026-04-18
draft: true
topics: ['energy']
tags: ['simulation', 'electricity-market', 'event-sourcing', 'merit-order']
tech: ['Go']
description: 'Event-sourced day-ahead electricity spot market simulator with merit-order dispatch, CfD bidding, and counterfactual pricing scenarios. Zero external dependencies.'
status: 'in-progress'
---

`~/projects/llm/energy/energy-market-sim` · commit `ff4e733` (2026-04-18)

## Goal

Simulate how a day-ahead electricity spot market works — generators submit supply bids, loads submit demand offers, and a clearing algorithm matches them to determine settlement prices. Inspired by [TGE][tge] (Polish power exchange), [EPEX SPOT][epex], and [Nord Pool][nordpool] auction mechanisms.

## Approach

### Merit-order dispatch

Generators are sorted by [short-run marginal cost][srmc] (SRMC) — cheapest first. The clearing algorithm dispatches them in order until demand is met. The last generator needed sets the uniform clearing price for that hour.

Fuel-type-specific SRMC formulas cover hard coal, lignite, gas, biomass, hydro (run-of-river and pumped), nuclear, and imports. CO₂ costs ([EU ETS][ets]) are integrated into each generator's bid.

### Event sourcing and CQRS

All state changes are immutable events: `BidSubmitted`, `MarketCleared`, `TradeExecuted`, `PriceSettled`. The current state is always derived by replaying the event log — never stored directly.

This makes counterfactual analysis trivial: change the CO₂ price, replay the same events through the clearing algorithm, and instantly see how dispatch order and settlement prices would differ. No re-simulation needed.

Read models ([projections][projection]) consume events asynchronously via an event bus — merit-order curves and price time series update in real time as events flow.

### CfD and must-run bidding

- [Contracts for Difference][cfd] (CfD): renewables bid negative (below zero) to guarantee dispatch, backed by a strike price
- Must-run thermal: lignite and coal plants bid negative to avoid expensive shutdown/restart cycles

### Output

- HTML reports with merit-order curves and price tables
- JSON export for further analysis
- Terminal display with summary statistics

## Outcome

- 15 Go source files, ~2,300 lines, **zero external dependencies** (stdlib only)
- 19 tests covering clearing logic, SRMC computation, and demand parsing
- Supports date range simulation, hourly filtering, and counterfactual CO₂/fuel price scenarios
- Integrates [PSE][pse] (Polish grid operator) system totals for demand data

[tge]: https://en.wikipedia.org/wiki/Towarowa_Gie%C5%82da_Energii
[epex]: https://en.wikipedia.org/wiki/EPEX_SPOT
[nordpool]: https://en.wikipedia.org/wiki/Nord_Pool
[srmc]: https://en.wikipedia.org/wiki/Merit_order#Short-run_marginal_cost
[ets]: https://en.wikipedia.org/wiki/European_Union_Emissions_Trading_System
[projection]: https://en.wikipedia.org/wiki/Event_sourcing
[cfd]: https://en.wikipedia.org/wiki/Contract_for_difference
[pse]: https://en.wikipedia.org/wiki/Polskie_Sieci_Elektroenergetyczne
