---
title: 'Mellum 2.1 12B, Flint 40B and Arete 27B: five small coding fixes'
date: 2026-11-13
draft: false
topics: ['ai', 'engineering']
tags: ['llm', 'agents', 'ai-coding', 'benchmark', 'llama-cpp', 'self-hosting']
description: 'I tested three self-hosted models on five small coding tasks from my own projects. Arete finished all five; Mellum was usually faster when it succeeded; Flint sometimes wrote correct code but failed to stop.'
---

I wanted to know whether a local coding agent could handle small, well-defined
changes without me stepping in. Not build an application from scratch: read an
existing module, fix one behavior, check it, and stop.

I gave Mellum 2.1 12B-A2.5B, Flint 40B-A2.5B and Arete 27B the same five tasks
from my Julia, Python and Ruby projects. All three used **OMP 18.20.0** as the
coding-agent harness, with the same limits. **Arete was the only model to finish all five successfully.**
Mellum was usually faster when it succeeded. Flint sometimes had the right code
on disk but kept working until it ran out of requests.

<!--more-->

## TL;DR

- **Arete 27B passed all five tasks** and stopped by itself every time.
- **Mellum 2.1 12B-A2.5B passed three of five.** Its successful runs took 28–70
  seconds, but its other two attempts did not produce working fixes.
- **Flint 40B-A2.5B passed two of five.** Four solutions passed the code checks,
  but two of those runs exhausted the request budget instead of finishing normally.
- These are **single attempts per model and task**, with weighted-median repeats
  reported separately. They are observations, not reliable success-rate estimates.

## The harness and configuration

The harness was **OMP 18.20.0**, a terminal coding agent. A Python benchmark runner
launched a fresh OMP process for each attempt, prepared the task workspace,
recorded model requests and tool events, enforced the limits, and graded the
result after the agent exited.

Inference ran on a single Radeon AI PRO R9700 with 32 GB of VRAM, using llama.cpp
behind llama-swap at a **210 W power cap**. Before each trial, the runner checked
that the server was idle and the cap was still 210 W.

Each model received the same setup:

- **Four tools:** `read`, `bash`, `edit` and `write`. No delegation or extra tool
  integrations.
- **Replacement edits:** OMP's `edit.mode` was `replace`, using search-and-replace
  rather than hashline editing.
- **Default system prompt:** no custom lean prompt. The task request described
  the required behavior and named the workspace and source file to read first.
  It also told the agent not to search parent directories.
- **Reasoning requested off:** `--thinking off`, with recorded requests sending
  `enable_thinking: false`. Flint's chat template had no reasoning switch, so
  this does not establish that its reasoning was actually disabled.
- **Fixed limits:** 20 model requests, 300 seconds per attempt, and a maximum of
  8,192 output tokens per response. A model request is one inference call, not
  one tool invocation.
- **No extra repository context:** skills, extensions, context files, repository
  rules, LSP and startup directory prewalking were disabled. Sessions were not
  saved, tool calls were automatically approved, and retries and model fallback
  were disabled.

This tested a single-agent read/edit/check loop, not my full everyday assistant
configuration. These original trials did **not** use an OS sandbox; telling an
agent to stay in its workspace is not a filesystem access restriction.

## How much VRAM do these models need?

I ran **one coding model at a time**, with llama-swap unloading the previous one.
The three models did not need to fit in VRAM together.

These are the actual quantizations used, their GGUF weight-file sizes, and GPU
memory readings from the recorded preflight checks with each model already loaded:

| Model | Weight quantization | Weight file | Observed resident VRAM |
| --- | --- | ---: | ---: |
| Mellum 2.1 12B-A2.5B | Q8_0 | 12.0 GiB | 16.7 GiB |
| Arete 27B | Q4_K_M | 16.0 GiB | 21.5 GiB |
| Flint 40B-A2.5B | Q4_K_M, abliterated variant | 22.5 GiB | 26.5 GiB |

The VRAM column is a **whole-GPU snapshot while idle with the model loaded**, not
a measured minimum or an inference peak. Weight files are only part of the cost:
the context cache, compute buffers and other GPU allocations also need space.
Longer contexts and concurrent requests can increase memory use. The 8,192-token
response limit above is not the total context size. GiB here means binary units,
converted from the recorded byte and MiB counts.

### Would an RTX 3090 or RX 7900 XTX be enough?

Both the [RTX 3090](https://www.nvidia.com/en-us/geforce/graphics-cards/30-series/rtx-3090-3090ti/)
and [RX 7900 XTX](https://www.amd.com/en/products/graphics/desktops/radeon/7000-series/amd-radeon-rx-7900xtx.html)
have **24 GB of VRAM**.

These memory readings suggest that **either card could fit Mellum Q8_0 or Arete
Q4_K_M, one at a time**, provided the context and batch settings leave enough
headroom. Arete has less room to spare. Start with one request slot and a smaller
context allocation rather than copying a large shared-context server profile.

**Flint used 26.5 GiB**, so I would budget **32 GB** for this profile.
Fitting it into 24 GB would require memory-saving changes, with possible speed
or quality trade-offs. I have not tested a 24 GB configuration.

For software support, llama.cpp offers
[CUDA for NVIDIA and HIP/ROCm or Vulkan for AMD](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md).
This benchmark used Vulkan on the R9700. **I did not benchmark either 24 GB card**,
so this is memory-fit guidance, not a claim that they match its timings. Neither
card can hold all three tested weight files in VRAM simultaneously.

## The five tasks

The tasks were small module-level slices pinned to exact source commits, not
whole application builds. The agent received the relevant code and any visible
smoke tests. Separate graders checked the required behavior after the run.

### Weighted median — Julia, cycling-speed estimates

My cycling project estimates riding speed from previous rides using a weighted
median. The result must be an observed speed. If the cumulative weight reaches
exactly half the total at one speed, the function must return that speed rather
than the next one. For example, two equally weighted speeds of 10 and 20 km/h
should give **10 km/h**, not 20.

The agent had to fix that boundary without breaking unsorted input, repeated
speeds, fractional or zero weights, or input validation. It also had to leave the
input vectors unchanged and preserve the behavior of per-bicycle speed profiles.

This was a **deliberately introduced regression**: the benchmark changed `>=` to
`>` in the real module. It was not a historical production bug.

### Signed daring — Julia, ski-game physics

Here, **daring means how bold or cautious a skier is**, separate from technical
skill. It adjusts how steep a slope the rider feels comfortable on, which affects
braking and descent speed.

The bug was a mismatch between two scales. Daring ranged from **−0.2 to +0.2**,
but the physics still treated it as a **0-to-1 value with 0.5 as neutral**. It
clamped negative values to zero, then subtracted 0.5. As a result, every cautious
rider received the same adjustment, zero daring incorrectly reduced capability,
and even the boldest valid rider received a reduction rather than a boost.

The ski game has a daring parameter centered on zero. Zero should leave a rider's
skill-derived capability unchanged. Positive daring should increase it; equally
negative daring should decrease it by the same amount, subject to the physical
bounds. Values outside the configured range should clamp at its limits.

The agent had to carry that behavior through control, descent speed and ride
statistics without changing the neutral rider's existing speed calibration. This
was a pure-physics slice: no rendering, terrain loading or running game was needed.

### Climate data root — Python, climate simulation

The application assumed its climate data lived inside the repository. The task
was to read the directory from a required `LLM_CLIMATE` environment variable and
expose it as `DATA_DIR`, a `pathlib.Path`.

Relative paths had to remain valid. Importing the constants module without the
variable had to fail immediately and name the missing setting. The fix must not
create the directory, require it to exist, or change unrelated constants. No
climate dataset or scientific package was needed to test this.

### Supported explanations — Ruby, pizza recommendations

The pizza recommender explains its choices using up to three supported tags,
ranked by their contribution weights. Unknown tags could occupy those three
slots before the code discovered that it had no description for them. A
high-ranked unknown tag could therefore crowd out a useful explanation.

The agent had to filter unsupported tags before selecting the top three, while
preserving the existing Polish descriptions, sentence formatting and neutral
fallback. The input contribution hash had to remain unchanged.

### Score coverage — Ruby, pizza recommendations

The pizza recommender could give extra points for tags the user did not care
about—for example, rewarding a spicy pizza when the user had no spice preference.
The agent had to ignore missing or zero preferences, including preferences that
cancelled each other out, without changing how actual likes and dislikes were scored.

## What counted as a pass

Every starting snapshot failed its external grader, and every reference fix
passed. That checked that each task had a detectable problem and a working
solution; it did not prove that the graders covered every possible bug.

A **strict pass** required more than correct code:

1. The external behavioral checks passed.
2. The agent exited successfully on its own, within the request and time limits.
3. It changed only the allowed implementation files. Tests were protected.
4. The trace audit found no access to benchmark answers or other prohibited sources.

The Ruby graders ran the real services with lightweight data records, without
booting Rails or a database. The Julia and Python checks likewise exercised the
selected modules rather than the full applications.

## Results

Times are agent wall-clock seconds, including startup, model loading when needed,
tool calls and the final answer, but excluding the external grading step.
The strict-pass totals below use the first attempt on each task.

| Task | Mellum 12B-A2.5B | Flint 40B-A2.5B | Arete 27B |
| --- | --- | --- | --- |
| Weighted median (cold load) | Failed: never edited the file | Correct code, request budget exhausted | Passed: 198 s |
| Signed daring | Passed: 70 s | Failed: timed out, no edit | Passed: 188 s |
| Climate data root | Passed: 28 s | Correct code, request budget exhausted | Passed: 58 s |
| Supported explanations | Passed: 70 s | Passed: 43 s | Passed: 61 s |
| Score coverage | Failed: crashes on a nil weight | Passed: 152 s | Passed: 56 s |
| **Strict passes** | **3 / 5** | **2 / 5** | **5 / 5** |

Counting only code correctness, Flint would score four of five. I keep that
separate from strict passes because an agent that writes the right fix and then
uses the rest of its budget is a different problem from one that writes the
wrong fix.

Weighted-median follow-ups did not change the strict-pass pattern. Arete passed
its warm repeat in **94 seconds**. Mellum made a broken edit and changed a
protected test. Flint also changed protected tests. These repeats are not added
to the five-task totals or substituted for the first attempts.

## What the failures looked like

**Arete finished.** Across the five first attempts, it used 7–18 requests per task
and stopped without exhausting the budget. It was the fastest successful model
on only one task, score coverage, but all five fixes passed.

**Flint kept working after a correct fix.** Its weighted-median and climate-root
attempts ended at the 20-request limit with code that passed the external checks.
It kept re-reading and re-running checks instead of finishing. The protected-test
edits in the median follow-ups were another failure to respect the task boundary.

**Mellum was quick when it succeeded.** It was the fastest successful model on
signed daring and climate data root. But the score-coverage fix crashed on a nil
weight. In the weighted-median repeat, it confused the values passed to Julia's
`sortperm(by=...)` with array indices. It also added a test claiming that the
median of `[10, 20, 30]` with equal weights was 10. The test reinforced its own bug
rather than catching it.

## Limits and takeaway

Five small tasks cannot establish which model is best for coding. There was one
main attempt per model and task, not enough repeats to estimate reliability or
timing variance. The cold and warm median timings also show why model loading
must be kept separate from claims about editing speed.

These results apply to **this OMP version, prompt, tool set and budget**. A
different harness or reasoning setting could change the outcome. The benchmark
also says nothing about whole-application integration or deployment.

For this test, Arete gave me the most useful result: five working fixes and five
clean finishes. Mellum offered shorter waits on some tasks, but I would need to
check its output carefully. Flint's correct fixes show why code quality and agent
completion need separate scores. Getting the patch right is only part of the job;
the agent also has to leave protected files alone and stop.
