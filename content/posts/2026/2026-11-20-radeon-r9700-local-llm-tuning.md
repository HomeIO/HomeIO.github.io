---
title: 'Running local LLMs on a Radeon AI PRO R9700: what actually made it faster'
linkTitle: 'Tuning local LLMs on a Radeon AI PRO R9700'
date: 2026-11-20
draft: false
topics: ['ai', 'engineering']
tags: ['llm', 'llama-cpp', 'amd', 'vulkan', 'self-hosting', 'speculative-decoding', 'benchmark']
description: 'Measured tuning notes for llama.cpp on a 32 GB Radeon AI PRO R9700: model choice, speculative decoding, KV-cache sizing, the GTT spill trap, quantization, batching, thinking control and one flag that silently did the opposite of what my config said.'
finding: 'Speculative decoding gave the biggest single win: n-gram drafting made file rewrites 3.5x faster on Devstral and 2.5x faster on Thinklite, with reasoning speed unchanged.'
---

I run my local models on one **AMD Radeon AI PRO R9700 with 32 GB of VRAM**.
Over the last two months I measured what actually changes speed, memory fit and
energy use on this card, mostly while benchmarking coding agents.

This post collects the tricks that held up under measurement, with numbers,
and two that did not. If you own an R9700, or another AMD card with llama.cpp,
most of this should transfer. **I will keep updating it** as I measure more.

<!--more-->

## TL;DR

- **Prefer mixture-of-experts (MoE) models.** On this card MoE models with
  2.5–4B active parameters decoded at **80–150 tok/s**; dense 24–31B models at
  **22–40 tok/s**, using 2–5x more energy per token.
- **Speculative decoding is the biggest single win.** N-gram drafting needs no
  extra weights and made file rewrites **3.5x faster on Devstral Small 2** and
  **2.5x faster on Thinklite 27B**, without slowing reasoning. An MTP head makes
  Qwen3.8 27B **41% faster** than a fine-tune of it whose GGUF dropped the head.
- **Check what your flags actually do.** llama.cpp *appends* repeated
  `--spec-type` values, so `--spec-type none` after a shared macro never
  switched speculation off. Seven of my profiles were speculating while their
  config said they were not.
- **Size the KV cache from the GGUF header**, quantize it to q8_0, and share one
  pool across request slots. Hybrid and sliding-window models get long context
  almost for free.
- **Watch GTT, not just VRAM.** On Vulkan, overflowing VRAM can silently spill
  into system RAM. I run every model under a guard that kills it instead.
- **Fill the slots for batch work.** Energy per token dropped **2–5x** with all
  request slots busy.
- **Turn thinking off for easy work.** A thinking profile used 7x more tokens
  than a no-thinking one for the same 12/12 score.
- **Power is not a tuning knob here.** 210 W is the R9700's minimum cap, and
  decode runs at that cap.

## The setup

- **GPU:** Radeon AI PRO R9700, 32,624 MiB usable VRAM, power cap **210 W**.
- **Host:** Ryzen 7 5800X3D, 32 GB RAM, Debian.
- **Inference:** llama.cpp on **Vulkan**, pinned to release **b11981** for most
  models. Builds are pinned per profile, because new architectures land at
  different times: Flint, for example, needs llama.cpp from PR #30928
  (October 2026) onwards.
- **Routing:** [llama-swap](https://github.com/mostlygeek/llama-swap) loads one
  main model at a time, plus small sidecars such as an embedding model.
- **Metering:** a small proxy in front of everything records each request's
  duration, tokens, energy share, and, since this week, its thinking level,
  reasoning tokens and the exact launch command that served it.

The numbers below come from three sources: an overnight benchmark of 29 text
models on 16 November (decode, prefill, parallel throughput, a 12-task quality
check, joules per token), the coding-agent campaigns, and short targeted speed
tests. Each section says which one it uses.

## 1. Model architecture matters more than tuning

The overnight benchmark separated the models more than any flag did:

| Model | Type | Decode, one request | Energy per token |
| --- | --- | ---: | ---: |
| gpt-oss 20B | MoE | 148 tok/s | 1.4 J |
| Mellum 2.1 12B-A2.5B | MoE | 115 tok/s | 1.7 J (0.52 J with 8 slots busy) |
| Qwen3.6 35B-A3B | MoE | 102 tok/s | — |
| Flint 40B-A2.5B | MoE | 92 tok/s | — |
| Qwen3.8 27B, with MTP | dense | 40 tok/s | 4.8 J |
| Arete 27B, no MTP | dense | 28 tok/s | 7.0 J |
| Gemma 4 31B | dense | 26 tok/s | 7.6 J |

*Overnight benchmark, 16 Nov 2026, Vulkan b11981, 210 W. Dashes: not in the
summary table. Decode used a story prompt with `ignore_eos`.*

The rule I settled on: **use an MoE model unless a dense model is clearly better
at the task**. On my coding benchmark the two best models were still dense 27B
models, so quality can justify the slower speed, but the default should be MoE.

Context length hurts dense models more. Qwen3.8 27B dropped from **37 to
25 tok/s** between 32K and 128K tokens of context, and reading a 128K prompt
took **319 s**. Qwen3.6 35B-A3B read the same prompt in **103 s** and still
decoded at **72 tok/s**. Agents that resend large contexts belong on MoE models.

## 2. Speculative decoding: three kinds, all worth checking

Speculative decoding drafts several tokens cheaply, and the real model checks
them in one pass. Accepted drafts are free tokens. The model verifies every
draft, so **the output does not change, only the speed**. That makes it the
safest optimization in this post.

llama.cpp supports several drafting methods. I use three.

### MTP heads: check the GGUF, not the model card

Some models ship a multi-token prediction (MTP) head, an extra layer trained to
predict the next tokens. Qwen3.8 27B has one. Arete 27B is a fine-tune of
Qwen3.8, but the GGUF I downloaded has 64 blocks instead of 65: **the MTP block
was dropped**. Same architecture, same size, very different speed:

| | Decode | Energy per token |
| --- | ---: | ---: |
| Qwen3.8 27B, `--spec-type draft-mtp` | 40.1 tok/s | 4.8 J |
| Arete 27B, no MTP head | 28.4 tok/s | 7.0 J |

Before you pick a quant of an MTP model, check whether the head survived. The
tensors sit in the file header, so this takes a second and loads nothing:

```sh
head -c 64000000 model.gguf | grep -a -o 'blk\.[0-9]*\.nextn\.[a-z_]*' | sort -u
```

No output means no MTP head. On my disk, Qwen3.8's GGUF has four `nextn`
tensors. Thinklite 27B, Nanbeige 4.3 33B and Devstral Small 2 24B have none.

### N-gram drafting: free, and huge for code edits

`--spec-type ngram-mod` drafts tokens by matching text that already appeared in
the context. It needs no extra weights. It shines exactly where coding agents
spend their time: rewriting a file with a small change, where most of the output
copies the input.

I measured it on the three models without an MTP head, with two prompts each:
**edit** (return a real 157-line source file with one function renamed) and
**reason** (explain an algorithm, with little to copy). Each run compared the
model's normal profile against an identical twin that differed only by
`--spec-type ngram-mod`.

| Model | Edit, off → on | Reason, off → on | Decision |
| --- | ---: | ---: | --- |
| Devstral Small 2 24B | 30.8 → **139.1 tok/s** (+352%) | 30.9 → 31.0 | enabled |
| Thinklite 27B | 28.9 → **102.2 tok/s** (+254%) | 29.4 → 29.3 | enabled |
| Nanbeige 4.3 33B | 26.2 → 26.2 | 26.6 → 26.5 | left off |

*Devstral: medians of three alternating repetitions. Thinklite: one
repetition, after a corrected baseline (see section 3). Nanbeige: partial run.*

Nanbeige gained nothing because it spent its token budget reasoning instead of
copying the file, so there was little to match. **N-gram helps when the output
repeats the input, and costs nothing measurable when it does not.** On reasoning
text the two variants stayed within 1% of each other.

### Draft models: DFlash for Muse Glimmer

Muse Glimmer 30B ships a separate 2.7 GB block-diffusion drafter (DFlash),
trained for that model. It runs with `--spec-type draft-dflash` and a
`--spec-draft-model`. With it, Muse decodes at **40 tok/s**. The drafter costs
VRAM, so budget for it: with the vision projector, the drafter and a 262K pool,
the profile sits around 28 GB.

## 3. The flag that did the opposite of what my config said

Most of my profiles start from a shared llama-swap macro, which includes
`--spec-type ngram-mod`. Profiles that should not speculate added
`--spec-type none` after it. I assumed the last value wins, as it does for most
llama.cpp flags.

**It does not.** For `--spec-type`, llama.cpp *appends* every value to a list
of drafting methods and deliberately skips its usual "specified multiple times,
last value wins" warning
([`common/arg.cpp`](https://github.com/ggml-org/llama.cpp/blob/master/common/arg.cpp)).
`ngram-mod` followed by `none` means n-gram stays on.

**Seven profiles** were speculating while their config said they were not,
including a profile literally named `nospec-bench`. I only noticed because the
Thinklite speed test reported thousands of accepted drafts on its supposedly
plain baseline. The fix is to give such profiles their full flag list instead of
the macro, or to keep speculation out of shared macros.

Two lessons:

- **Combine values in one flag** (`--spec-type a,b`) instead of repeating it,
  and read the server log to confirm what is active.
- **Record what the server actually ran.** My proxy now stores a hash of the
  exact launch command for every request, with the full command kept once per
  hash. That record found this bug.

## 4. KV cache: size it from the GGUF, quantize it, share it

Model weights are only part of VRAM. The KV cache grows with context, and on
some models it costs more than the weights. You can compute it from the GGUF
header before loading anything:

```text
KV bytes per token = sum over full-attention layers of
                     n_head_kv × (key_length + value_length) × bytes per element
```

With a q8_0 cache, bytes per element is 34/32 ≈ 1.06 (f16 is 2). I checked the
formula against llama.cpp's own allocation logs and it matched to the MiB:

| Model | Configuration | Predicted | Measured |
| --- | --- | ---: | ---: |
| Mistral Small 3.2 | 64K, shared | 5,440 MiB | 5,440 MiB |
| Gemma 4 31B | 16K, 2 slots | 1,955 MiB | 1,955 MiB |
| Qwen3-VL 8B | 128K, 8 slots | 9,792 MiB | 9,792 MiB |
| Flint 40B-A2.5B | 262K, shared | 3,808 MiB | 3,808 MiB |

What I do with that:

- **Quantize the cache to q8_0** (`--cache-type-k q8_0 --cache-type-v q8_0`).
  It halves the cache compared with f16. Some profiles go further to q4_0 to fit
  a larger pool. Treat that as a trade-off to verify per model, not a default.
- **Prefer models with cheap context.** Hybrid and sliding-window architectures
  pay KV only on some layers. Qwen3.6 35B-A3B and Gemma 4 26B-A4B cost about
  **10.6 KiB per token**, so 256K tokens take about 2.7 GB. Mistral Small costs
  **85 KiB per token**, eight times more.
- **Share one pool across slots.** `--kv-unified` with `--kv-unified-per-slot N`
  gives several request slots one shared pool instead of splitting the context
  evenly. Mellum runs 8 slots on a 600K-token pool, each capped at 128K.
  Remember that slots then share the pool: eight slots cannot all use 128K at
  once.
- **Sliding-window layers do not grow with context.** llama.cpp sizes them to the
  window times the slot count, so Gemma 4's local layers stay small at any
  context length.

## 5. Watch GTT: the silent VRAM overflow

On Linux, an AMD GPU can also use GTT: system RAM mapped for the GPU. When a
model plus its cache does not quite fit, the Vulkan driver may place some buffers
there instead of failing. The model still loads and still answers, just much
more slowly, and nothing tells you why.

I would rather have a crash. Every model runs under a small guard script. After
the server reports ready, it samples the process's resident GTT from the kernel's
DRM statistics four times a second. Above **512 MiB** it kills the server, so the
problem shows up as an error instead of a mystery slowdown. 512 MiB is about 2.6
times the healthy baseline on this machine. The guard also sets RADV's
`nogttspill` hint, which reduces spilling but
[does not guarantee it](https://github.com/ggml-org/llama.cpp/issues/13765).

The overnight benchmark proved the guard's worth. Two profiles crashed only
when **every advertised slot was busy at once**: a Qwen3.6 profile at 8
concurrent requests (619 MiB of GTT) and a Gemma-based model at 3 (541 MiB). One
request at a time, both worked. **Test your profiles with all slots full**, then
lower `--parallel` or the pool size until they stay in VRAM.

## 6. Quantization: Q4_K_M is the sweet spot here

On this card, higher-precision quants cost speed and energy without a visible
quality gain on my checks:

- **Mistral Small 3.2 Q6_K vs Q4_K_M:** 30% slower, 26% more energy per token,
  no better score.
- **Qwen3.6 35B-A3B Q5 vs Q4:** no better score, 6–7% slower decode, slower load.
- **Qwen3.8 27B IQ3_S vs Q4:** barely faster alone (42 vs 40 tok/s) and
  **slower with two requests** (29 tok/s combined; board power dropped to
  128 W, so the GPU was starved, not saturated). Use IQ3 only to free memory.
- **Very low bits to fit big models:** NVIDIA's official 2-bit build of Nemotron
  3.5 Bolt 74B-A9B, made to fit 24 GB cards, loads and runs on this card with a
  128K pool.
  How much quality the 2-bit build gives up is still being measured.

My quality check has only 12 tasks, so differences of one task are noise. The
consistent finding is the cost side: on this card, more bits bought me nothing
I could measure.

## 7. Batch through slots

Running several requests at once costs little extra on MoE models, so energy per
token falls sharply when every slot is busy:

| Model | Energy per token, one request → all slots busy |
| --- | --- |
| Mellum 2.1 (8 slots) | 1.74 → 0.52 J |
| Qwen3.6 35B-A3B batch profile (8 slots) | 1.84 → 0.67 J |
| Bielik 11B | 4.27 → 0.81 J |
| Mistral Small 3.2 | 5.24 → 1.56 J |

Mellum reached **399 tok/s** with 8 requests at once. Dense 27–31B models gain
much less: they are already memory-bound with two slots. If you run batch jobs,
give them an MoE profile with many slots and keep it full.

## 8. Thinking: turn it off when the task is easy

Thinking models spend a large share of their output on reasoning. On my coding
benchmark, reasoning was **49–87% of all output tokens**, depending on the
model. That is fine for hard problems and wasteful for easy ones.

The clearest case: on the 12-task quality check, Qwen3.6 35B-A3B with thinking
used **13.6K tokens**; the same model with thinking off used **1.8K** and also
scored 12/12. That is about 7x the time and energy for nothing.

Two practical points for llama.cpp:

- **Request settings override launch defaults, key by key.** llama-server starts
  from the launch command's `--chat-template-kwargs`, then lets each key in the
  request's `chat_template_kwargs` replace it, then applies a top-level
  `reasoning_effort` ("none" disables thinking). A router can launch a model at
  `xhigh` effort while a client still asks for `medium`, and the request wins.
- **Do not trust a "thinking off" switch until you see the request.** In one
  coding harness, the flag for disabling thinking still sent
  `enable_thinking: true`. Log the request body, not the CLI label.

## 9. Power, swaps and other things that are not knobs

- **Power:** decode runs at the card's **210 W cap** (186–209 W measured), and
  210 W is also the lowest cap the R9700 allows. On this card, energy per token
  comes from the model choice, not from the power limit.
- **Model swaps cost 30–100 s.** Group work by model, and let the last model stay
  loaded. Ping-ponging between two dense models wastes more time than any flag
  saves.
- **Long-context recall varies by model, not just by window size.** Mistral Small
  3.2 found a planted code at 32K but not at 64K, despite a 128K window. Flint
  found it at 64K, then rambled past it. Test recall at the lengths you use.

## What I would do first on a new R9700

1. Pick an MoE model for the task unless a dense one is clearly better.
2. Check the GGUF for an MTP head. If it has one, use `--spec-type draft-mtp`.
   If not, try `--spec-type ngram-mod` and measure on your own workload.
3. Compute the KV cache from the GGUF header, quantize it to q8_0, and size one
   shared pool for your slots.
4. Run every profile with all slots full and watch GTT.
5. Prefer Q4_K_M. Go lower only to fit, higher only if a measurement says so.
6. Turn thinking off for routine work.
7. Read the server's startup log and record the exact launch command next to
   every result.

## Limits

These are measurements on **one card and one machine**, mostly on llama.cpp
release b11981 with Vulkan. I did not compare Vulkan with ROCm/HIP on the R9700.
Speed tests used short prompts and a few repetitions: good for large effects
like n-gram drafting, not for differences of a few percent. The 12-task quality
check can only spot large regressions. Newer llama.cpp builds will change some
of these numbers, which is one reason I plan to keep this post updated.
