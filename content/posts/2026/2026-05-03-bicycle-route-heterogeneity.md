---
title: "How We Build Scenic Bicycle Routes Using Nature Heterogeneity"
date: 2026-05-03
tags: ["routing", "osm", "cycling", "algorithm"]
---

## The Problem with Shortest-Path Routing

Most bicycle route planners give you the shortest or fastest path between two points. On a bike, this is almost never what you want. A 60 km route that hugs a busy national road is "optimal" by distance, but miserable to ride. What cyclists actually want is a route that:

- avoids heavy traffic and urban sprawl
- passes through varied, interesting landscapes
- discovers quiet back roads you would never find on your own
- balances distance with enjoyment

This post explains how we built an algorithm that does exactly that, using **landscape heterogeneity** — the mathematical idea that a mosaic of different land covers is more interesting than a monoculture.

<!-- TODO: screenshot — side-by-side viewer comparison showing base route (red, straight) vs adventurous route (green, wavy) on the same map. Caption: "Base route follows the highway; adventurous route weaves through forests and wetlands." -->

## What Makes a Landscape "Interesting"?

Intuitively, a route that passes through forest, then meadow, then along a river, then through wetlands, is more interesting than 50 km of continuous pine forest. The first landscape has **heterogeneity**; the second has **homogeneity**.

Our core insight: **we can measure this heterogeneity from OpenStreetMap data** and use it as a routing signal.

### The Six Nature Categories

From OSM tags, we extract six nature categories that cyclists actually care about:

| Category | OSM Tags | Why It Matters |
|----------|----------|----------------|
| Water (linear) | `waterway=river`, `waterway=stream` | Riparian corridors are cool, scenic, and often have dedicated bike paths |
| Water (area) | `natural=water`, `water=pond/lake` | Lakes and ponds create focal points and microclimates |
| Wetland | `natural=wetland` | Rare, biodiverse, usually flat and quiet |
| Forest | `landuse=forest`, `natural=wood` | Shade, silence, pine scent |
| Meadow | `landuse=meadow`, `landuse=grass` | Open views, rolling terrain |
| Scrub / Orchard | `natural=scrub`, `landuse=orchard` | Transitional edges where wildlife congregates |

Each category gets a weight reflecting its scarcity and sensory impact. Water features are weighted highest (2.0×) because they are rare, visually dominant, and strongly correlate with cooler temperatures and tailwinds. Wetlands get 1.8×. Forests get 1.0×. Meadows and scrub get lower but still positive weights.

<!-- TODO: screenshot — map excerpt with nature features colored by category (water=blue, forest=dark green, meadow=light green, wetland=purple, scrub=orange). Caption: "Raw OSM nature features around Włocławek." -->

## Measuring Heterogeneity at a Point

For any location on the map, we compute a **richness score** by looking at nature features within an 800 m radius:

```
score = Σ category_weight × packing_factor
```

The **packing factor** captures how tightly features are clustered around the center point. A feature 50 m away contributes more than one 700 m away. Specifically:

```
weight = 1.0 - (distance / 800m)
packing_factor = 0.5 + average_weight
```

This means features at the very edge contribute 0.5× their category weight, while features clustered at the center contribute up to 1.5×. A cell with water at its center and forest at its edge scores higher than the reverse — which matches human intuition about what feels "scenic."

<!-- TODO: screenshot — interestingness heatmap overlay on the map. Square grid cells colored by score (low=yellow, high=red). Caption: "Heterogeneity heatmap — red cells are mosaic hotspots where multiple nature categories overlap." -->

### The Minimum-Count Gate

A category only counts if it has **at least 2 features** in the radius. This prevents a single stray tree line from registering as "forest presence." Categories with 4+ features get an extra 0.3 bonus, rewarding genuine biodiversity hotspots.

### Water Bonus

If any water feature is present, we add a flat +1.0 to the score. Water is so strongly correlated with scenic quality that it deserves special treatment.

### Sparse-Area Penalty

If the total feature count in the radius is below 5, the score is multiplied by 0.4. This suppresses false positives in genuinely empty agricultural areas where a single hedgerow might otherwise register as a mosaic.

## From Points to Zones: Clustering Hotspots

Computing richness for every 300 m cell in a 50×50 km area gives us thousands of scores. The next step is finding **hotspots** — contiguous regions where heterogeneity is consistently high.

We use a two-step process:

### Step 1: Grid Scoring

Compute richness for every cell in a 300 m grid. Cells scoring above a threshold (default 2.0) become candidate hotspots.

### Step 2: Single-Link Clustering

Candidate hotspots are clustered using **single-link agglomerative clustering** with a 1 km chain distance. Two hotspots join the same zone if they are within 1 km of each other, or if a chain of hotspots exists connecting them with each link under 1 km.

Why single-link? Because it captures **corridor-shaped** scenic areas — like a river valley where heterogeneity is high all along the watercourse, even if individual hotspots are spaced a few hundred meters apart. Complete-link or centroid clustering would break these corridors into fragmented blobs.

### Zone Properties

Each zone exposes:

- **center_lat, center_lon**: score-weighted centroid (not geometric center — high-scoring cells pull the centroid toward them)
- **score**: sum of member cell scores
- **density**: score / area (km²), so compact, intense zones rank above sprawling, weak ones
- **top_categories**: which nature categories dominate the zone
- **peak_score**: highest individual cell score in the zone

Zones are sorted by density descending. Singletons (zones with only 1 member) are filtered out.

<!-- TODO: screenshot — map with translucent green circles showing clustered zones. Different sizes = different zone areas. Caption: "Mosaic zones clustered from heterogeneity hotspots. Larger circles = more members." -->

## The Density Field: From Waypoints to Corridors

Earlier versions of our algorithm treated zones as **waypoints** — the router would explicitly visit each zone center. This had a problem: if a zone center happened to be on a bad road, the route was forced to visit it anyway. And in sparse rural areas, the closest zone might consume the entire distance budget, leaving no room for exploration.

Our current approach uses a **continuous density field** instead of discrete waypoints.

### Building the Field

We create a coarse 1 km grid over the entire route bbox. For each cell, its value is the weighted sum of nearby zone densities:

```
cell_value = Σ zone_density × (1.0 - distance/3000m)
```

Zones within 3 km contribute, with linear falloff. A cell near three moderate-density zones can have a higher value than a cell near one high-density zone — which is correct, because three overlapping scenic corridors are more interesting than one.

### Using the Field in Routing

During graph weight preparation, every road edge gets a bonus proportional to the density field value at its midpoint:

```
bonus = min(density × 0.0125, 0.25) × adventurousness
weight *= 1.0 - bonus
```

At maximum adventurousness (1.0), edges near dense mosaic zones get up to 25% cheaper — which means A* will naturally route through scenic corridors without being forced to visit specific points. The route flows through interesting areas organically, like water finding a valley.

<!-- TODO: screenshot — same map with one adventurous route highlighted. Show how the route deviates from the straight line to pass through a green corridor (forest+meadow overlap). Caption: "The density field pulls the route toward the green corridor without forcing a visit to any specific point." -->

## Candidate Diversity: Swing Waypoints

With the density field alone, every route at a given adventurousness would follow the same corridor. To give riders choices, we generate **diverse candidates** using geometric swing waypoints:

| Strategy | Description |
|----------|-------------|
| Direct | No waypoints — let the density field do everything |
| Left/Right Near | 5 km off the corridor axis at midpoint |
| Left/Right Mid | 10 km off axis |
| Left/Right Far | 15 km off axis |
| Double Left/Right | Two waypoints on same side, creating an arc |
| S-Curve | Waypoints on opposite sides, creating a serpentine shape |

Each candidate is just A* from start → waypoint(s) → end. The density field ensures the legs between points naturally flow through scenic areas. Candidates are deduplicated by edge-set Jaccard similarity (threshold 0.5) so riders get genuinely different shapes, not minor variations.

<!-- TODO: screenshot — viewer showing 4-5 candidate routes on the same map in different colors. One is a left swing (wide arc), one is right swing, one is S-curve. Caption: "Diverse candidates for the same start/end — each explores a different side of the scenic corridor." -->

## Loop Routes: Same Idea, Different Geometry

For round-trip routes (start = end), we use a **polar attractor field**: 16 sectors × 10 radial rings around the start point. Each attractor is scored by scenic value × distance bonus. The algorithm then builds loop skeletons (ellipse, teardrop, figure-8, triangle) and routes through them with anti-reuse logic to avoid riding the same road twice.

The key insight is the same: **density attracts, geometry diversifies**.

<!-- TODO: screenshot — loop mode showing 6-8 loop candidates radiating from a single point. Different colors and shapes (ellipse, teardrop, triangle). Caption: "Loop candidates for a 50 km ride from Włocławek — each shape explores a different direction." -->

## Validation: Does It Actually Work?

We validate by comparing our adventurous routes against the shortest path on real OSM data. On a 62 km Włocławek → Toruń test route:

- **Base (shortest)**: 60 km, mostly on national road 91, flat, noisy
- **Adventurous**: 62 km, weaves through 4 nature zones, passes 2 lakes, 1 wetland complex, and 3 villages. Elevation profile has 3× more variation.

The adventurous route is only 3% longer but visits 8 distinct land-cover types versus 2 for the base route. Rider feedback (informal, n=4) consistently prefers the adventurous route for weekend rides, though they note it requires more navigation attention.

<!-- TODO: screenshot — elevation profile chart showing two lines. Base route is flat (blue); adventurous route has 3 distinct climbs (green). Caption: "Elevation profiles: base route (blue) vs adventurous (green). The adventurous route has 3× more elevation variation." -->

## Technical Stack

- **OSM extraction**: `osmium-tool` extracts bbox from Poland PBF (~2 GB)
- **Graph**: NetworkX MultiDiGraph with road-type penalties
- **Spatial index**: Shapely STRtree for fast proximity queries
- **Scoring**: Vectorized numpy/shapely bulk queries (30× faster than per-cell loops)
- **Cache**: Per-tile OPL + bbox-level graph+scenic cache, invalidated by content hash
- **Elevation**: SRTM3 tiles via Mapzen, bilinear interpolation

<!-- TODO: screenshot — webapp job queue panel showing 3 jobs with progress bars. One is "done", one is "routing", one is "candidates". Caption: "Background job queue with live progress — each stage is parsed from the worker's stdout." -->

## Future Work

- **Industrial proximity penalty**: Large factories and logistics parks create visual and air-quality dead zones that current scoring misses
- **Seasonal weights**: Forest is more valuable in summer (shade) than winter; wetlands are more valuable in autumn (bird migration)
- **Surface-aware heterogeneity**: A gravel road through meadow+forest might score higher than asphalt through the same landscape, because the surface matches the terrain

## Go Rewrite & Performance Optimization

We recently rewrote the pipeline from Python to Go. The rewrite was driven by two goals: single-binary deployment and faster cold-start times. The Go version is now the production engine.

### Why Go?

The Python version worked well but had friction: it required a virtualenv, had ~2 second import overhead, and the webapp needed a separate Python process for each job. A single Go binary eliminates all of that.

### What we optimized

The initial Go rewrite was correct but slow — ~36 seconds for a cold run, only 3× faster than Python. Profiling revealed the real bottleneck was not A* routing (which takes ~40 ms) but **weight preparation**: computing scenic bonuses for every edge in the graph.

`PrepareWeights` iterates over all ~1 million edges and performs 5 spatial queries per edge (nature, scenic points, settlements, cities, busy roads). That's 5 million R-tree searches per route request.

**Fix: parallel edge processing.** We split the edge list into 8 chunks and process each chunk in its own goroutine. Since edges are independent, this is embarrassingly parallel. On an Apple M4 Pro, this alone cut weight preparation from ~23 s to ~4 s.

**Fix: dense node index.** The A* implementation originally used `map[int64]float64` for `gScore` and `cameFrom`. Maps are fast, but slice indexing is ~5× faster. We added a `BuildIndex()` method to the Graph that remaps sparse OSM node IDs to dense `[0, n)` indices. A* now uses `[]float64` and `[]int` instead of maps.

**Fix: cache key bug.** When using `-pbf` input, the cache key was derived from the temp OPL file path (`/tmp/cycle-route-*/...`), which is different on every run. The cache never hit. We now key the cache by bbox hash, giving a 1.4× warm-run speedup.

### Results

| | Python | Go (initial) | Go (optimized) |
|---|---|---|---|
| **Cold run** | 118 s | 36 s | **17 s** |
| **Warm run** | 60 s | 25 s | **6 s** |
| **Speedup** | 1× | 3× | **7–10×** |

The warm run is now dominated by graph deserialization (~1 s) and A* routing (~0.04 s). The remaining ~5 s is osmium OPL extraction from the PBF, which is a fixed external cost.

### Test Route Details

All benchmarks use the same real-world test case:

- **Start**: Włocławek, PL — `52.6482°N, 19.0672°E`
- **End**: Toruń, PL — `53.0138°N, 18.5984°E`
- **Distance**: ~60 km straight-line, ~62 km adventurous route
- **OSM extract**: Poland PBF (1.9 GB), extracted to 27 MB OPL for the bbox `18.5°E–19.2°E, 52.5°N–53.1°N`
- **Hardware**: Apple M4 Pro, macOS, Go 1.24
- **Profile**: gravel, adventurousness 0.5

### Detailed Timing Breakdown (Go optimized, warm run)

| Stage | Time | % of total |
|---|---|---|
| OPL extraction (osmium) | ~0 s (cached) | 0% |
| Graph deserialization | 1.0 s | 17% |
| Weight preparation (parallel) | 4.5 s | 75% |
| A* routing | 0.04 s | <1% |
| Grid scoring | 1.5 s | 25% |
| **Total warm** | **~6 s** | **100%** |

The A* router explores ~130k nodes (26.6% of the 490k-node graph) to find the 62 km adventurous path. With scenic weights, edge costs vary by up to 33% from physical length, so the Haversine heuristic is quite optimistic — but the route quality is worth the exploration cost.

### What the Go rewrite replaced

| Component | Python | Go |
|---|---|---|
| Parser | Custom OPL parser | Same, rewritten |
| Graph | NetworkX MultiDiGraph | Custom adjacency list + dense index |
| Spatial index | Shapely STRtree | `tidwall/rtree` |
| Cache | gzipped pickle (tile-level) | msgpack (bbox-level) |
| Router | NetworkX A* | Custom A* with slice heap |
| Webapp | Flask + ThreadPool | stdlib `net/http` + goroutine workers |
| Binary size | — | ~7 MB single binary |
| Tests | ~112 | **135** + 10 benchmarks |

### What's next

The remaining warm-run time is dominated by `PrepareWeights` (~4.5 s). The next optimization would be **grid-based scenic precomputation**: instead of doing 5 R-tree queries per edge at request time, precompute scenic density on a 100 m grid once after graph build. Edge weights become simple grid lookups. This would cut warm runs from ~6 s to ~2 s.

Other possibilities:
- Native Go PBF parser (eliminate 8 s osmium subprocess on cold runs)
- Skip scenic weight prep entirely for base/shortest routes
- k-d tree for nearest-node lookup (eliminates 490k-node linear scans)

## Summary

The core idea is simple: **interesting cycling happens at the boundaries between ecosystems**. By measuring nature heterogeneity from OSM data, turning it into a continuous density field, and letting the router flow through it like water through a watershed, we generate routes that are measurably more varied than shortest-path alternatives — without forcing artificial detours.

The algorithm is fully offline (no APIs), runs in **~6 seconds on a warm cache** (was ~60 s in Python), and produces routes that cyclists actually want to ride.

<!-- TODO: screenshot — the "Plan a route" panel in viewer.html. Show red A marker, green B marker, the slider for adventurousness, and the loop-mode toggle. Caption: "Click anywhere on the map to set start (A) and end (B), then hit Generate." -->
