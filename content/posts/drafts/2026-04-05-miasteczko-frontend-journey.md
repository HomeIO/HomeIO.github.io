---
title: 'Four UI frameworks in three days — finding the right frontend for a Julia transport simulator'
date: 2026-04-05
draft: true
tags: ['julia', 'react', 'electron', 'ui', 'miasteczko']
description: 'From CImGui to Bonito.jl to React+Electron — how the Miasteczko.jl presentation layer evolved through rapid prototyping.'
---

When your simulation engine can generate bus networks, timetables, passenger flows, and economics dashboards — you need a way to actually look at the results. This is the story of finding the right frontend for [Miasteczko.jl](/projects/miasteczko-jl/), a transport planning simulator built in Julia.

<!--more-->

## Day 1: Leaflet HTML — just get something on screen (April 5)

The first attempt was the simplest possible thing: generate static HTML pages with [Leaflet][leaflet] maps. Roads, stops, routes as map overlays. Click a route, get a popup with its timetable. Click a hub, see a weekly table.

It worked for quick visual checks — is this route going where I think it is? — but it was a dead end for anything interactive. No state management, no filtering, no side-by-side comparison. Every change meant regenerating HTML files.

Still, it established something important: **map-first** is the right paradigm for this tool. Tables and charts are secondary to seeing routes on a real map.

## Day 2: CImGui — the native desktop attempt (April 7)

[CImGui][cimgui] (Julia bindings for Dear ImGui) with GLFW and ModernGL. Immediate-mode GUI — you redraw everything every frame, no retained widget tree.

The appeal: native desktop window, no browser overhead, direct GPU rendering. I got a working viewport with zoom/pan, roads and buildings drawn via ImDrawList, click-to-open floating windows for stops and routes, hover tooltips, even label collision avoidance.

The problems became clear quickly:

- **Map rendering is hard.** Drawing roads and buildings manually with line primitives looks rough compared to MapLibre's vector tile rendering. No anti-aliasing on diagonal roads, no smooth zoom levels, no satellite imagery fallback.
- **Text rendering limitations.** ImGui's font atlas doesn't handle Polish diacritics well out of the box. Ł, ą, ź — all the characters you need for station names.
- **Layout constraints.** Immediate-mode is great for debug tools and settings panels, not for complex data-heavy dashboards with resizable panels and tabbed interfaces.

CImGui would be perfect for a game engine's debug overlay. For a "transit authority workstation" with maps, tables, and charts — wrong tool.

## Day 3 morning: Bonito.jl — the Julia-native web attempt (April 8, 08:40)

[Bonito.jl][bonito] is a Julia package for building web UIs reactively — similar in spirit to R Shiny or Dash. The idea: stay in Julia, render in the browser, use MapLibre for maps, wrap it in Electron for a desktop feel.

I built a proof-of-concept in a few hours: MapLibre map, sidebar with route list, click-to-select, Electron window with a progress bar, even got the DM Sans font with proper Polish character support.

It validated the direction — Electron + web rendering + MapLibre was clearly right. But Bonito itself had friction:

- **State management.** Bonito's reactive model works for simple dashboards but gets unwieldy when you have 15+ interacting components (floating windows, map layers, data tables, filters).
- **Hot reload.** Every change required restarting the Julia process — minutes of wait time vs. Vite's sub-second hot module replacement.
- **Ecosystem.** The React/TypeScript ecosystem has battle-tested components for every UI pattern I needed. Bonito's component library is small.

The PoC's job was to answer one question: *does this architecture work on Apple Silicon?* It did. Time to build the production version.

## Day 3 afternoon: React + Oxygen.jl + Electron — the one that stuck (April 8, 15:03)

Six hours after the Bonito PoC, the full React rewrite was running. The architecture:

- **Backend:** Julia serves a JSON API via [Oxygen.jl][oxygen] (routes like `/api/meta`, `/api/buildings`, `/api/routes`)
- **Frontend:** React 19 + TypeScript + Vite + MapLibre GL JS
- **Desktop:** Electron window with loading screen and progress bar

This separation turned out to be the key insight. The simulation engine doesn't need to know about UI. It produces data, serves it over HTTP, and any frontend can consume it. The React app is the primary consumer, but the same API could feed a Jupyter notebook, a CLI dashboard, or a third-party GIS tool.

What the React app delivers today:

- Interactive MapLibre map with roads, buildings, stops, routes, rail tracks
- Floating detail windows — click any stop or route to inspect it
- Sortable data tables for routes, stops, vehicles
- Time-distance diagrams
- Passenger flow charts
- Economics dashboard with per-route financials
- Regional macro view for multi-town corridor analysis

The whole thing builds with `make ui` and hot-reloads with `make ui-dev`.

## What I'd tell past me

1. **Start with the rendering engine, not the framework.** The real question was never "CImGui vs React" — it was "can I render maps well?" MapLibre answered that definitively. Everything else followed.

2. **PoCs are cheap, production rewrites are expensive — but sometimes worth it.** The Bonito PoC took 3 hours and saved days of going down the wrong path. The React rewrite took 6 hours but resulted in something maintainable.

3. **Separate data from presentation.** The Oxygen.jl JSON API was the best architectural decision. It makes the simulation results accessible to any tool, not locked into one UI framework. If React dies tomorrow, the API stays.

4. **Julia for compute, web standards for UI.** Trying to do everything in Julia (Bonito) felt like swimming upstream. Julia is exceptional at numeric simulation. HTML/CSS/JS is exceptional at user interfaces. Let each do what it's good at.

[leaflet]: https://leafletjs.com/
[cimgui]: https://github.com/ocornut/imgui
[bonito]: https://github.com/MakieOrg/Bonito.jl
[oxygen]: https://github.com/ndortega/Oxygen.jl
