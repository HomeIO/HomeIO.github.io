---
title: "Claude orchestrating a swarm of Kimi workers: a day of autonomous refactoring"
date: 2026-05-27
url: /posts/2026/2026-05-27-claude-orchestrates-kimi-workers/
tags: ["agents", "ai-coding", "orchestration", "opencode", "kimi", "claude", "refactoring"]
description: "What happens when you let one Claude session conduct eight opencode workers running Kimi K2.6 in parallel git worktrees. Notes from a single day that landed 61 commits, removed 17k lines, and ended with an autonomous loop merging diffs by itself."
topics: ["ai", "engineering"]
math: false
---

For about a year I have been running Claude in the loop on a legacy C++ codebase — a port of an old strategy game to macOS Apple Silicon. The work is the kind that is not particularly hard but is *very tedious*: untangling layered dependencies, ratcheting include counts down, deleting dead modules that nobody has compiled in twenty years. Claude is excellent at it, but Claude's time is expensive, and a lot of the edits look more like substitutions than decisions.

So this week I tried something different: **let Claude be the conductor, and let cheaper, faster models do the substitutions**.

The setup, in one sentence: one Claude (Opus 4.7, 1M context) session orchestrates up to eight [opencode](https://opencode.ai/) workers running Kimi K2.6, each in its own git worktree, each with a strictly-scoped task brief. Claude designs the briefs, reviews the diffs, runs the build, merges what passes, escalates what fails. The workers do the typing.

What follows is a writeup of the day and the failure modes I had to engineer around. The codebase specifics do not matter — substitute "your big legacy project" wherever I say CTP2. The pattern generalises.

---

## Why two models instead of one

Claude alone can do all of this. I have spent dozens of sessions watching it do exactly that, one file at a time. The bottleneck is not capability — it is throughput. A migration that touches a hundred files takes a hundred sequential edits. Even with prompt caching and batched tools, the wall-clock dominates.

The economics also shift. Claude's outputs are highly valuable per token: I want it deciding *what* to change, not typing out the change. Kimi K2.6 via OAuth is cheap-or-free and fast. If I can keep eight Kimis busy in parallel and have Claude review their diffs, I get the best of both: Claude's judgement on the design, Kimi's throughput on the keystrokes.

The skeleton then becomes:

```
Claude (designer + reviewer)
   │
   ├── opencode worker 1  ──►  git worktree 1  ──►  oc/refactor-1
   ├── opencode worker 2  ──►  git worktree 2  ──►  oc/refactor-2
   ├── opencode worker 3  ──►  git worktree 3  ──►  oc/refactor-3
   ├── opencode worker 4  ──►  git worktree 4  ──►  oc/refactor-4
   └── ...
   
                 ▲                                       │
                 │             review.sh + merge.sh      │
                 └───────── cherry-pick onto master ◄────┘
```

Each worker operates in genuine isolation — its own checkout of the repo, its own branch, its own copy of the build directory. Workers cannot stomp on each other. The orchestrator pulls accepted commits onto `master` one at a time.

---

## The TASK brief

Most of the trick is in how you write the brief. A worker running a 200B-parameter model on a sprawling C++ codebase will go off-script in a hundred small ways unless every parameter of the task is nailed down in the prompt. I converged on this shape:

```markdown
# Task: <one-line goal>

## Background
<why this task exists, what larger migration it serves, which ratchet test it pushes forward>

## The migration pattern for this file
### Current state (file.cpp line N):
   <exact code snippet>
### After migration:
   <exact code snippet>
### Call sites
   <grep results: which files call the affected symbol, what they need to change>

## Files you may edit
1. `path/to/main.cpp` — <what to change>
2. `path/to/consumer.cpp` — <what to add>

## Out of scope (DO NOT touch)
- any file not listed above
- any header (.h) file
- the ratchet baseline in test_player_view.cpp

## If the build breaks elsewhere
<escape hatch: commit [WIP] with the breakage; don't chase a cascade>

## Acceptance
- `mise exec -- meson compile -C build ctp2 ctp2_fast_tests` succeeds.
- `./build/ctp2_fast_tests` reports SUCCESS.
- Diff touches only the files listed above.

## Commit (REQUIRED — do not stop after the edit)
**You MUST run `git commit` before exiting.** Saying "Ready to commit" 
without invoking the command is a task failure.

```
git add <files>
git commit -m "refactor(scope): <one-line summary>

<body>"
```

## Working directory
`/path/to/worktree`, branch `oc/refactor-N`.
```

Three things matter most:

1. **`claimed_paths`**: the explicit "files you may edit" list. Workers will sometimes need to edit a file outside this list to make the build pass. That is a yellow flag, not a green light — every out-of-scope edit gets read line-by-line during review.
2. **The migration pattern with BEFORE/AFTER snippets**: a paragraph of prose is not enough; a model with limited context-fidelity needs to see the exact transformation it should produce.
3. **The mandatory `git commit`**: Kimi specifically tends to end with "Ready to commit" or "Changes complete" and then *exit cleanly without committing*. If you don't make the commit a REQUIRED step with exact commands, you lose half your work to silent no-ops.

---

## Failure modes you will hit

I scaled up from 2 workers to 4 to 8 over the course of the day. Every increase exposed a new failure mode. Here are the ones worth knowing about before you try this.

### Workers exit without committing

The most common one. The worker says "I have prepared the diff, ready to commit", then exits. The branch stays at master. The edits sit in the working tree, uncommitted, until you reset the worktree and lose them. Recovery is straightforward (git status + git diff in the worktree, commit on the worker's behalf), but it's expensive in attention.

**Fix**: every TASK brief ends with a `## Commit (REQUIRED — do not stop after the edit)` section containing the exact `git add` and `git commit` commands. Phrased as a contract, not a suggestion. After this, the rate dropped from ~60% silent-no-commit to under 10%.

### Workers stomp out of scope

Worker assigned to migrate `FileA.cpp` also edits `FileB.cpp` because "the build wouldn't pass otherwise". Sometimes that fix is correct (a transitive include broke, the worker patched it sensibly). Sometimes it is wrong (the worker decided some legacy code path was "dead" and commented it out, then went on its way). Auto-acceptance would land subtle bugs.

**Fix**: review every out-of-scope diff hunk individually before merging. If it is genuinely necessary and looks right, accept and note in the batch retrospective. If it is overreach, reject and rewrite the brief.

### Stale base produces phantom "reverts"

This one took me an hour to diagnose. When the same wave's worker A merges to master at 13:00 and worker B (whose worktree was reset to master at 12:30, before A's merge) finishes its own work at 13:15, *worker B's `master..oc/refactor-B` diff appears to revert worker A's changes* — because the 3-dot diff shows everything reachable from B but not from master, and B's base predates A's commit. The cherry-pick then tries to undo A's work and either conflicts loudly or, worse, lands quietly.

**Fix**: `spawn.sh` runs `git reset --hard master` on the worker's worktree as its very first step, immediately before invoking opencode. The worker always sees the absolute current tip of master at launch. This single change eliminated all phantom-revert merges.

### Failed merges retry every poll cycle

The orchestrator loop polls every 15 seconds. If a merge fails (e.g., a real conflict), the next poll tries the same merge again, fails again, logs another escalation. After ten minutes you have forty identical escalation lines and the real signal is buried.

**Fix**: per-branch skip markers in `.orchestration/skip/<branch>`. Once a branch fails review or merge, the loop marks it and stops trying. Clearing the marker is a manual step (which itself is a small forcing-function to actually look at what went wrong).

### macOS pgrep doesn't support `\b`

The loop detects "worker is busy" via `pgrep -fl "opencode run --dir.*ctp2-refactor-1\b"`. On macOS, `pgrep -f` uses POSIX BRE, which silently treats `\b` as a literal. The pattern never matches. The loop concludes all workers are idle, drains the backlog into "would spawn", then exits. You spawn eight workers and the orchestrator quits 17 seconds later thinking it's done.

**Fix**: exact-path matching. `pgrep -f "opencode run --dir /absolute/path/to/ctp2-refactor-1 "` (note the trailing space — anchors the end of the directory name).

### Laptop sleep masquerades as a stuck worker

If you're running on battery and the lid is open and you walk away for half an hour, macOS may decide to nap. opencode workers are paused mid-task. Their logs show no recent activity. Their processes are alive in pgrep. They look exactly like a stuck Kimi session.

**Fix**: `caffeinate -i` before launching a long wave. (Also, if you ever see a "frozen" worker, check `ls -lt` on the log file — if the last write was right before suspected sleep, you have the wrong diagnosis.)

---

## The auto-merge gate

Once you've handled the failure modes above, you can flip on `--auto-merge` and let the loop run unattended for short batches. The gate is conservative on purpose. A commit lands without my eyeballs *only if all of these are true*:

1. **Build is clean** (`meson compile` rc=0)
2. **Fast unit tests pass** (`./build/ctp2_fast_tests` SUCCESS)
3. **Diff stays within `claimed_paths`** — no extra files
4. **No new cross-layer includes** — the architecture ratchet test catches this; gs/ code adding `#include "gfx/..."` would fail the suite
5. **Commit message matches the conventional-commit pattern** for the scope

Anything that misses one of these escalates to a log file. The loop writes `[timestamp] reason` and skip-marks the branch. No prompt, no popup, no email — just a file the orchestrator (me) checks when I come back.

This is the right trade-off for *mechanical* refactoring: pattern-matched edits where there is a single correct answer per file. It is decidedly not the right trade-off for design work. If I asked a Kimi worker to "break the combat resolution out of `ArmyData.cpp` into its own service", I would not auto-merge the result. I would read every line.

---

## What today actually looked like

Concrete numbers from one day on one codebase, just to give a sense of scale:

| Metric | Result |
|--------|-------:|
| Commits landed on `master` | 61 |
| Lines of dead code deleted | ~17,200 |
| Files deleted | 348 |
| Direct calls to a layer-violating singleton (`g_director`) eliminated | 102+ |
| Direct calls to another (`g_soundManager`) eliminated | 40 |
| Architecture ratchet baselines locked | 12 |
| Coverage measurement infrastructure | added; baseline 31.3% lines on simulation core |
| Largest parallel batch | 8 workers |
| Smallest parallel batch | 3 workers |
| Wall-clock for a clean 3-worker batch | ~3 minutes from spawn to all-landed |
| Auto-merges in the last clean batch | 3 of 3, zero escalations |

The day was front-loaded with a lot of manual driving — I started each batch myself, reviewed every commit, merged each branch by hand. By late afternoon the auto-merge gate was solid enough that I could seed a backlog of three small tasks, run `caffeinate -i bin/loop.sh --auto-merge`, and watch three clean commits roll into master without touching anything.

The most satisfying moment was a batch where one of the three workers refused to commit anything — its three assigned files all called a helper function that the migration's neutral header didn't yet forward. The worker correctly identified the blocker, reverted its own work-in-progress changes, and exited without a commit. The other two workers landed cleanly. The orchestrator skipped the empty branch, locked the new ratchet baseline at the actual current count, and moved on. *That* is what autonomous refactoring should look like: confident moves, honest no-ops, no false positives.

---

## Day two: the harness pays for itself

I picked the harness back up the next morning and ran four more waves on top of the day-one foundation. Two of them were more of the same — bounded mechanical refactors. The other two were something I had not planned: **the same orchestration pattern, but with tests as the deliverable instead of refactors**. The workers don't care which.

The four waves:

- **Wave 6** (3 workers): swap the last `sound/gamesounds.h` includes in `gs/.cpp` over to the lightweight `gs/core/audio_types.h` forward-declaration header. Six files in three branches, gs/.cpp sound-include ratchet 7 → 1.
- **Wave 7** (3 workers + ~90 min of orchestrator design): design a new observer interface — `tiledmap_observer`, in the same shape as the existing audio and render observers — and migrate twenty call sites in `gs/.cpp` off `g_tiledMap->X()` direct calls. The interface, the UI-side adapter, and the registration wiring were mine; the per-file call-site rewrites were the workers'. gs/.cpp gfx-include ratchet 29 → 9.
- **Wave 8a** (3 workers): all tests. Spy-based contract tests for `tiledmap_observer` and `audio_observer`, plus three new architecture ratchets. Test count 28 → 59 in the fast suite.
- **Wave 8b** (**8 workers in parallel**): more tests. Spy tests for the third observer (`render_observer`), pure unit tests for `MapPoint`, extensions to existing fixture-based suites (`buildqueue`, `happy`, `randgen`, `save-load`), and another batch of architecture ratchets. Test count 59 → 98 fast, 132 → 186 unit. 1250 lines of new test code in about fourteen minutes of wall-clock.

The headline number for day two is **+87 new unit test cases**, all green, **zero touches to production code**. The test-coverage waves are *refactoring-safe by construction* — they only assert behaviour through the stable observer interfaces and pure-value APIs, never against internals that the in-flight migrations are rewriting. Useful when you have a long backlog of include-swaps still queued.

### A new failure mode: shared-anchor merge conflicts

Wave 8a hit a fresh failure I hadn't seen before. Two workers, both creating new test files, both briefed to register their file in `meson.build` "right after `test_observer.cpp`". Both inserted at the same line. The cherry-picks conflicted on each other.

**Fix**: in wave 8b's briefs I gave each new-file worker a **distinct anchor** in the meson sources list — worker 1 inserts after the audio observer entry, worker 2 inserts after the randgen entry, and so on. Eight workers later, zero conflicts. The lesson is general: when N workers all touch a registry, assign each one a different anchor *in the brief*. They don't coordinate on the fly; you have to coordinate them upfront.

### The pitfall-5a-rate dropped through the floor

The "worker exits without committing" failure that dominated day one — about 60% raw rate, dropped to ~10% after I made the commit step mandatory in the brief — kept dropping. The trick was *moving the REQUIRED commit instructions to the top of the brief instead of the bottom*. Workers were reading the migration steps, executing them, and then exiting before reaching the commit section at the end. Across waves 7, 8a, and 8b — eleven workers — exactly zero needed orchestrator-side recovery.

### The orchestrator-design / worker-throughput rhythm is the real value

The wave 7 cadence is what I want to highlight. While I sat down to design `tiledmap_observer.h`, `tiledmap_observer.cpp`, and the UI-side adapter — about 90 minutes of real thought — the workers from wave 6 were committing in the background. By the time my new observer compiled and passed the smoke suite, the wave 6 batch was already merged. When the three wave 7 workers were ready to spawn on the new interface, I had also drafted their briefs. From the orchestrator's seat the day felt continuous; from the workers' seat it was three discrete rounds. **The asymmetry between "designing the next abstraction" and "applying it everywhere" is exactly what this pattern monetises.**

### Updated numbers across both days

| Metric | Day 1 | Day 2 | Cumulative |
|--------|------:|------:|-----------:|
| Refactor commits on `master` | 61 | 12 | 73 |
| Test commits on `master` | — | 11 | 11 |
| Lines of dead code deleted | ~17,200 | ~0 | ~17,200 |
| New test code added (lines) | — | ~1,500 | ~1,500 |
| Fast unit-test cases | 28 | +70 | **98** |
| Full unit-test cases | 132 | +54 | **186** |
| Architecture ratchets locked | 12 | +6 | 18 |
| Largest parallel batch | 8 | 8 | 8 |
| Worker silent-no-commit rate | ~10% (post-fix) | 0% (0/11) | — |

The day-two coverage waves alone are a story I would not have written before this experiment: **eight workers, in parallel, adding test coverage to a legacy codebase without me writing a single line of test code myself, and without any of those tests having to be rewritten when the next refactoring wave lands**. That last clause is the load-bearing one.

---

## What I would build differently if I started over

A few things I would now do from day one:

- **Worktrees, not branches in a single checkout.** The `git worktree` model means each worker has its own files on disk. No race conditions on the working directory, no fighting over the index, no "wait, why does my build artifact have someone else's edit". This is the single biggest correctness multiplier in the setup.
- **Always-reset spawn.** `spawn.sh` should reset the worker's worktree to current `master` as a precondition to running the model, every single time. The "stale base produces phantom reverts" bug above is purely the absence of this discipline.
- **Skip markers, not retry-forever.** A branch that fails its merge gate once should be skipped until manually unblocked. Re-attempting is almost never the right answer.
- **Bounded scope per task brief.** Files-you-may-edit and files-you-must-not-touch are non-negotiable sections of the brief. Reviewer fatigue is the real bottleneck; tight scope minimises reviewer load.
- **Mandatory commit step, phrased as a contract.** Treating "did the worker actually commit?" as a likely failure mode rather than a guarantee saves half your work.
- **Coverage tracking from the start.** Even if you don't enforce a ratchet on it, watching coverage as a per-wave time series gives you immediate feedback when a refactor wave is changing behaviour rather than just shape. Today's setup uses `gcovr` (not `lcov` — lcov choked on a generated header in this codebase) writing a CSV row per wave.

---

## The honest tradeoffs

This pattern is not free. Two costs that matter:

**Reviewer attention is the real bottleneck**, not worker throughput. Eight workers all finishing in five minutes is not actually faster than three workers finishing in five minutes if you need to read eight diffs sequentially. I am running my own auto-merge gate to dodge this, but the gate's strictness is also doing real work — it is keeping me from approving things I should have read. A weaker gate would land more bad commits.

**The model gap matters more than I expected**. Kimi K2.6 is not Claude. It will pick a strategy your brief did not anticipate (sometimes cleaner than your prescription, sometimes wronger). It will sometimes write code in a style that doesn't match the project. It will sometimes invent dead-code claims ("this function is never called, I'll just comment it out") that you have to grep-check yourself. The Claude-reviews-Kimi gate is not theatre; it is load-bearing.

What you are buying with this setup is **throughput on bounded mechanical changes** at a tiny fraction of the cost of doing them with a frontier model. If your project has a long tail of those changes — and most large legacy projects do — the leverage is real.

---

If you want to try the same thing, the orchestration code is about 200 lines of bash. The hard part is not the loop; it is writing TASK briefs that a non-frontier model can execute and a frontier model can verify in seconds.

---

## Day three: scouts instead of workers

The first two days were about *execution* — bounded mechanical changes, applied in parallel. By day three the execution pipeline was solid enough that a new bottleneck appeared: **knowing what to execute next**. The TODO list was "modernise the codebase", which is not a task brief. I needed a discovery phase that could run in parallel with execution, producing a backlog of scoped, file-level tickets that future worker waves could consume.

Enter **scouts**.

### The idea

Instead of spawning workers to *edit* code, spawn scouts to *read* code and write tickets. Each scout gets 35 source files. It analyses them for modernisation opportunities — raw pointers that should be `std::unique_ptr`, C-style arrays that should be `std::vector`, global state that should be injected, SOLID violations that block testability — and writes one ticket per issue. The ticket is a markdown file with a standard frontmatter schema: source file, priority (H/M/L), category (memory/solid/global/container/testability/interface/smell), a code snippet, and a suggested direction. Nothing more. The scout does not edit code. It only documents.

The goal is to turn "modernise the codebase" into a concrete backlog: `H-memory--gs-gameobj-Unit-cpp--01.md`, `M-testability--ai-diplomat-cpp--03.md`, and so on. When a future worker wave needs its next three tasks, it pulls from this backlog instead of needing a Claude session to scope them.

### Dynamic prompt generation

I did not hand-craft fifty prompts. A 70-line bash script (`generate-prompts.sh`) walks the source tree, finds every `.cpp` and `.h` outside third-party `libs/`, splits them into chunks of `SCOUT_CHUNK_SIZE` (default 35), and emits a self-contained prompt per chunk. With 1,742 game files this produces about 50 scouts. The prompt includes:

- the exact file list the scout must read
- a priority rubric (H = memory/globals/SOLID, M = testability/interfaces, L = smells)
- the ticket filename format: `<priority>-<category>--<sanitized-path>--<counter>.md`
- an idempotency rule (see below)

Running `make scouts-generate` regenerates the prompts from the current source tree, so the backlog stays aligned with the code as migrations land.

### Pool manager with concurrency limit

Fifty scouts is too many to spawn at once. I wrote a small Python pool manager (`scout-pool.py`) that keeps at most `SCOUT_POOL_SIZE` scouts active (default 5). When one finishes, the next starts immediately. This gives steady load instead of batch spikes, and it handles Ctrl+C gracefully — it stops launching new scouts but lets active ones finish and save state.

The manager prints a status line every ten seconds:

```
[11:23:18] Done: 12/50 (24%) | Active: 5/5 | Failed: 0 | Remaining: 33
  Running: scout-013, scout-014, scout-015, scout-016, scout-017
```

### Idempotency: restart without duplication

The biggest practical concern was restarts. If a scout crashes, or the laptop sleeps, or opencode rate-limits, you need to resume without re-analysing files that already have tickets. I built two layers of idempotency:

1. **Pool state**: `pool-state.json` tracks completed and failed scouts. Restarting the pool manager skips completed scouts automatically.
2. **Ticket-level deduplication**: every scout prompt instructs the session to list existing tickets, grep for its target file, and skip if the same category/issue is already covered. Some duplicates between scouts are inevitable (adjacent files may notice the same cross-file pattern), so `make scouts-dedup` groups by `source_file + category` and keeps only the most detailed ticket.

This means you can safely run `make scouts-spawn`, Ctrl+C after three hours, and run it again. It will pick up exactly where it left off.

### Makefile targets

The whole workflow is exposed through the project Makefile:

```bash
make scouts-generate       # split source tree into ~50 prompts
make scouts-spawn          # start pool manager (5 concurrent by default)
make scouts-retry          # re-run only scouts that failed previously
make scouts-dedup          # remove duplicate tickets
make scouts-status         # show progress
make scouts-reset          # wipe state and start from scratch
```

### First results

The scouts started running while I wrote this section. Five scouts were active within a minute of `make scouts-spawn`. The first few logs show Kimi reading through `ai/diplomacy/` headers and identifying raw `new[]` allocations in `AgreementMatrix`, global `g_player` access in `Diplomat.cpp`, and a C-style `char m_name[64]` in `Foreigner.h` that should be `std::string`. Each finding became a ticket file in `.scouts/tickets/` within minutes of the scout starting.

I do not yet know how many tickets the full run will produce — estimates range from 200 to 800 depending on how aggressively the scouts flag borderline issues. The execution team (Claude + worker waves) will sort by priority, validate against current code, and feed the H-priority memory-management tickets into the next refactoring batch.

### What this adds to the pattern

The scout layer turns the orchestration from a **single-phase** system (Claude scopes → workers execute) into a **two-phase** system (scouts discover → Claude prioritises → workers execute). The scouts are cheap — they only read and write markdown, they do not compile, they do not run tests. A scout session costs a fraction of a worker session. And the backlog they produce is persistent: it survives across days, across model switches, across laptop sleeps.

The pattern generalises to any codebase where "what should we clean up?" is harder than "how do we clean up this one file?".
