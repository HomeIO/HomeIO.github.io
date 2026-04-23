---
title: 'heft'
date: 2026-03-18
draft: true
topics: ['tools']
tags: ['disk-analysis', 'cli', 'tui', 'sqlite']
tech: ['Go', 'Bubble Tea', 'SQLite']
description: 'Fast disk space analyzer with SQLite caching, 18 auto-categorizing cleanup detectors, duplicate finder, and interactive TUI. Scans 685 GiB in under a minute.'
status: 'in-progress'
---

`~/projects/llm/heft` · commit `ff175f8` (2026-03-18)

## Goal

Understand what's eating disk space and safely reclaim it. Not just a `du` replacement — heft caches scan results in [SQLite][sqlite], auto-categorizes files, and groups cleanup recommendations by how risky they are to delete.

## Approach

### Scan and cache

[fastwalk][fastwalk]-based parallel filesystem traversal computes real disk usage via `stat.Blocks × 512` (actual allocated blocks, not file size). Results are cached in SQLite with [WAL mode][wal] — entries ≥ 1 MB get individual rows, smaller files aggregate to parent directory totals. Scans are resumable (Ctrl-C safe).

After the initial scan (~685 GiB in under a minute on Apple Silicon), queries are instant from cache.

### Auto-categorization

Files are tagged during scan: `node_modules`, `vcs`, `xcode`, `containers`, `venv`, `trash`, `brew`, `cache`, `build`, `logs`, `media`, `archive`. Categories power both the TUI display and the advisor.

### Cleanup advisor — 18 detectors

Recommendations are grouped by recoverability tier:

| Tier | Risk | Examples |
|------|------|----------|
| 5 — Rebuildable | Safe | Build artifacts (`target/`, `_build/`), `node_modules`, virtualenvs, Rails logs |
| 4 — Re-downloadable | Safe | Homebrew cache, [Ollama][ollama] models |
| 3 — Regeneratable | Low | Browser caches (Chrome, Firefox, Safari), [Darktable][darktable] cache, app caches |
| 2 — Archivable | Medium | Steam games, duplicate files, stale files, Trash |
| 1 — Review needed | High | Large media files |

Each detector is configurable: `remove`, `suggest`, `ask`, `info`, or `ignore`. Paths can be acknowledged (suppressed from future runs) with prefix matching.

### Duplicate finder

Two-phase detection: SQL query finds same-size candidates, then MD5 hashing (cached) groups actual duplicates. Avoids hashing the entire filesystem.

### Interactive TUI

[Bubble Tea][bubbletea]-based terminal UI. Navigate with arrow keys, expand/collapse directories, sort by size/name/age/category, search, export to JSON.

## Outcome

- ~5,700 lines of Go, 35 tests
- 6 commands: `scan`, `advise`, `view`, `dupes`, `top`, `stale`
- Pure Go SQLite ([modernc.org/sqlite][modernc]) — single binary, no C dependencies
- JSON export for feeding to other tools

[sqlite]: https://en.wikipedia.org/wiki/SQLite
[fastwalk]: https://github.com/charlievieth/fastwalk
[wal]: https://en.wikipedia.org/wiki/Write-ahead_logging
[ollama]: https://en.wikipedia.org/wiki/Ollama
[darktable]: https://en.wikipedia.org/wiki/Darktable
[bubbletea]: https://github.com/charmbracelet/bubbletea
[modernc]: https://pkg.go.dev/modernc.org/sqlite
