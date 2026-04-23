---
title: 'Nowa Rzeczywistość (New Reality)'
date: 2026-04-22
draft: true
topics: ['climate']
tags: ['simulation', 'climate-adaptation', 'agent-based-model', 'julia', 'typescript', 'education']
tech: ['Julia', 'React', 'TypeScript', 'Vite']
description: 'A climate adaptation management simulator set in Poland, 2020–2200. You manage a village through escalating climate crisis — every decision has a cost in money, energy, and lives. The core lesson: adaptation is brutally expensive, and decarbonization was the cheaper path we did not take.'
status: 'in-progress'
---

`~/projects/llm/climate/new-reality` · 55,557 tests passing

## Goal

Build a simulator that answers a question most people do not feel viscerally: **what does it actually cost to live through climate change?** Not abstract global numbers — the concrete, month-by-month cost of keeping a real community alive as the world warms.

The player governs a Polish village (~200 residents, scalable) across 180 years. This is not a game about stopping climate change. It is about surviving it. The 2020s serve as the emotional anchor — a familiar world with normal winters and predictable seasons. You need to feel what "normal" was to understand what is lost.

## Approach

### Simulation architecture

The backend is a custom Julia engine with monthly ticks and crisis zoom to daily resolution during extreme events. Seven sequential steps per tick: climate → hydrology → agriculture → infrastructure → health → economy → community. Each household is a full agent with ~40 properties (building era, insulation, heating type, solar, water source, residents with ages and health conditions).

When a heatwave hits and the grid fails, the simulation does not calculate "12% × 40% = X deaths." It iterates over every household: *Does this home have AC? Off-grid power? Who lives here? Are they elderly, ill, alone?* Narrative emerges from simulation.

Key systems:
- **Climate generator** — deterministic trend from IPCC AR6 / EURO-CORDEX projections + seasonal cycle + interannual noise + Poisson extreme events (heat waves, floods, storms)
- **Heat cascade chain** — heat → grid overload → AC failure → indoor temperature → mortality, with full building physics (thermal mass, insulation, ventilation, shading)
- **Flood & storm cascades** — rain → river level → crop/road/building damage → water contamination → disease outbreak
- **Agent-based households** — initialized from Polish building archetypes (pre-war timber, PRL brick/silicate, "kostka", modern), with realistic demographics
- **Village-level systems** — power grid with load/failure mechanics, water treatment, road network, agriculture with growing degree days

### Infrastructure projects — the core gameplay

46 infrastructure projects across 7 domains (water, energy, food, housing, health, transport, communications) plus 6 nature-based solutions, 6 policy projects, and 3 monitoring systems. Each project has:

- **Scaling** — per-unit (homes insulated) or coverage-% (% with rainwater harvesting)
- **Cost curves** — solar panels get cheaper over time, concrete gets scarcer
- **With/without projection** — before committing, see 5-year modeled outcomes: lives saved, damage prevented, break-even timeline
- **Prerequisites & synergies** — 27 synergy pairs amplify each other (insulation + heat pump = 35% more savings than either alone)
- **Unique mechanics** — no two projects feel identical. Some are instant (emergency water tanks), some gradual (household-by-household rollout), some are technology bets with sweet spots, some are nature-based and take years to mature

![Village dashboard — three-column mission control showing People, Infrastructure, and Climate & Land status](/img/new-normal/village.png)

The village dashboard is designed as an ecological control room. Seasonal color shifts, contextual "Did you know?" tips, and progressive disclosure (deaths hidden until they happen) keep the interface readable while the underlying simulation grows increasingly complex.

### Budget and resource accounting

The funding page is where strategic decisions happen. The player allocates village income across up to 5 active programs using sliders, with a visual budget split bar and predicted completion dates. Every złoty spent on adaptation is a złoty not spent on schools, culture, or simply living.

![Funding page — interactive budget allocation with sliders for active programs](/img/new-normal/funding.png)

Resources are tracked as first-class educational metrics: energy (by activity), fuels (coal, gas, gasoline with realistic price curves), water, food, CO₂, and nature area restored. The player sees total and per-capita consumption, and how projects change those numbers over time.

### Projections and decision support

Each project has a detailed analysis page with three-scenario projections (without / current pace / fully implemented), factor-specific charts, cost curves over time, prerequisite chains, synergy links, and advisor opinions.

![Project detail — Grid Reinforcement with 5-year impact projection across three scenarios](/img/new-normal/project-grid-reinforcement.png)

The projection engine runs a lightweight forward model to show concrete differences: coal saved, CO₂ reduced, fuel savings, payback period, deaths avoided. This is where the educational argument lives — the numbers that show why early action pays off.

### History and long-term trends

The history page tracks long-term trends: 12-month rolling average temperature, extreme event frequency, deaths, food prices, population, and quality of life. The warming signal becomes visible through the seasonal noise.

![History charts — temperature trends, extreme events, deaths and food prices over decades](/img/new-normal/graphs.png)

### Educational layer

Seven domain advisors each maintain a science notebook with 3 educational entries covering real concepts: insulation physics, heat pumps, thermal mass, growing degree days, soil organic matter, heat mortality curves, wetland hydrology. The game teaches passively through consequences; notebooks teach actively for curious players.

The "It Used to Be..." system periodically compares current state to stored 2020s baseline memories: "December without real snow. Again. The children don't remember building snowmen."

## Outcome

- **55,557 tests passing** — including automated 80-year strategy playthroughs (do nothing, early mover, late reactor, energy focus, nature first, balanced portfolio)
- **62 projects** with unique mechanics, 43 narrative triggers, 25 achievements
- **3 cascade chains** (heat, flood, storm) with stochastic extreme event generation
- **10 impact factors** with scientific units, all projects tagged with realistic effects
- **Factor ledger** — analytical decomposition showing exactly how each project contributes to every metric
- **Proper actuarial damage model** — EAD = probability × vulnerability × asset value, with project damage reductions tracked per hazard
- **Migration mechanics** — young adults leave first when QoL drops, families arrive when the village adapts well
- **Decade summary screens** with counterfactual analysis: "Without insulation, 12 more deaths would have occurred"

## What I learned

- **Simulation-first design changes everything.** When narrative emerges from agent state rather than a separate story engine, the player feels the consequences as their own decisions. The first heat death hits harder when you know that household had no AC and the grid failed because you delayed the transformer upgrade.
- **Cost curves are a powerful pedagogical tool.** Showing solar panel costs declining over time teaches technology dynamics better than any explanation. The player naturally starts asking: "What is the sweet spot?"
- **The factor ledger was worth the complexity.** Being able to decompose every metric into "base + project contributions" makes the simulation inspectable. Players (and I during debugging) can see exactly why a number is what it is.
- **Julia's type system and multiple dispatch made the architecture natural.** Each module produces typed structs, the next module consumes them. No serialization layer needed within the backend. The frontend gets JSON, but internally everything is strongly typed.
- **Progressive disclosure is essential.** The dashboard hides deaths until they happen, mental health until it degrades. A screen with everything visible at once would paralyze the player. Reveal complexity as it becomes relevant.

## Stack

- **Julia** — simulation engine: climate models, agent-based household simulation, infrastructure systems, event generation. Serves JSON API.
- **React + TypeScript + Vite** — browser UI: dashboard, project selection, reports, narrative events, visualizations.
- **Recharts** — all charts (projections, history, resources)
