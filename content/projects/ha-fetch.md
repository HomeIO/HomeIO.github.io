---
title: 'ha-fetch'
date: 2026-04-17
draft: true
topics: ['smart home']
tags: ['home-automation', 'data-pipeline', 'home-assistant']
tech: ['Go']
description: 'CLI tool that fetches historical sensor data from Home Assistant and stores it as weekly CSV files — smart backfill, incremental updates, deduplication.'
status: 'in-progress'
---

`~/projects/llm/smart-home/ha-fetch` · commit `f57b9f9` (2026-04-17)

## Goal

Get sensor history out of [Home Assistant][ha] and into a format that analysis tools can consume. HA's built-in history is great for quick lookups but awkward for bulk analysis — ha-fetch bridges that gap with incremental CSV exports.

## Approach

### Fetching

Connects to HA's [history API][ha-api] (`/api/history/period/`) using a long-lived access token. On first run, backfills 2 years of data day by day. Subsequent runs fetch only from the latest stored timestamp — incremental by default.

Exponential backoff retry logic handles rate limiting (429) and server errors (5xx). Requests are paced with smart sleep between non-empty days to avoid overloading HA.

### Storage

Data lands in weekly CSV files named by [ISO week][iso-week] (e.g., `2026-W07.csv`). Format: `sensor_id,value,updated_ts` with Unix timestamps.

Records are deduplicated by sensor + timestamp key on every merge. Running ha-fetch multiple times is safe — idempotent by design.

### Sensor catalog

Supports 100+ sensor types from a shared `ha-sensors` package: power, temperature, humidity, occupancy, wind, rain, voltage, and more. HA states are normalized to numeric values (`on`→1, `off`→0). Invalid states (`unavailable`, `unknown`) are silently skipped.

## Outcome

- Single Go binary, 13 tests
- Handles HA's [minimal response format][minimal] (entity_id on first change only)
- Resumable: Ctrl-C safe, picks up where it left off
- `-since` flag for forced re-fetch from a specific date
- Feeds data to [home-analysis](/projects/home-analysis/) and [home-forecast](/projects/home-forecast/)

[ha]: https://en.wikipedia.org/wiki/Home_Assistant
[ha-api]: https://developers.home-assistant.io/docs/api/rest/
[iso-week]: https://en.wikipedia.org/wiki/ISO_week_date
[minimal]: https://developers.home-assistant.io/docs/api/rest/#get-apihistoryperiodtimestamp
