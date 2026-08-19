---
title: 'Should I self-host an LLM? I got three answers, and the first two were wrong'
date: 2026-08-19
draft: true
topics: ['ai', 'energy']
tags: ['llm', 'hardware', 'gpu', 'cost-analysis', 'thermal-modeling']
description: 'I spend real money on language model APIs and own an idle desktop. Working out whether to self-host took three passes — each time new measurements reversed the conclusion.'
---

I spend somewhere between 300 and 500 zł a month on large language model (LLM)
access — two chat subscriptions plus per-token API billing. I also own a desktop
PC that mostly sits idle. The obvious question: should the second thing replace
part of the first?

I answered it three times. The first two answers were wrong, and each time it
was a measurement rather than an argument that overturned them. This post is the
whole chain — the hardware analysis, the memory-bandwidth physics, the token
economics, and finally where the waste heat goes.

<!--more-->

## TL;DR

- The machine's memory was running at **2667 MT/s instead of its rated 3200** —
  a 20% performance gain sitting unclaimed in a BIOS menu.
- **Memory bandwidth, not capacity, decides inference speed.** More RAM buys
  bigger models, never faster ones.
- Adding capacity would have made things **worse**: 128 GB needs four dual-rank
  modules, and this platform degrades badly past four ranks.
- **First answer: don't self-host.** Renting `gpt-oss-120b` costs ~12× less than
  the electricity to generate the same tokens locally.
- **Second answer, after adding photovoltaics (PV): still don't**, but the
  margin narrows from 12× to 2×.
- **Third answer, after measuring my actual workload: buy one graphics card.**
  The job is batch inference on 24–32B open models, not the frontier models I
  assumed I was paying for — and that inverts the economics.
- **Fourth answer, after renting the card for a dollar: not that card.** The 32B
  vision model needs 20.98 GiB of weights against 23.56 GiB usable. It does not
  fit, so the payback I had calculated rested on a configuration that cannot
  exist.
- The waste heat raises a room by **0.64 °C over three hours** — and in winter
  it is not waste at all.

## The machine

| Component | Spec |
|---|---|
| CPU | AMD Ryzen 7 5800X3D — 8 cores / 16 threads, Zen 3 |
| RAM | 32 GB DDR4 (2 × 16 GB dual-rank), **configured at 2667 MT/s** |
| GPU | Radeon RX 5500, **4 GB** VRAM, Navi 14 (RDNA1) |
| Board | Mini-ITX, B450 chipset, **2 DIMM slots** |
| Link | PCIe 4.0 ×16, negotiated clean, zero errors |
| Storage | 28 GB root (5.9 GB free), 1.8 TB home |
| OS | Debian, kernel and graphics stack **frozen at 2021** |

Two things in that table are free money.

**The memory is underclocked.** The modules are Crucial Ballistix rated
3200 CL16, but `dmidecode` reported `Configured Memory Speed: 2667 MT/s`. The
extreme memory profile ([XMP][xmp], branded A-XMP on this board) had never been
enabled. Since inference speed scales with memory bandwidth, that is roughly
**+20% for 0 zł**.

**Resizable BAR is off.** `lspci -vv` showed the graphics card advertising
support for a 4 GB base address register (BAR) while capped at 256 MB. Enabling
[Resizable BAR][rebar] reduces overhead when the processor writes into video
memory — exactly the traffic pattern of hybrid inference.

A pleasant surprise in the same output: the graphics slot negotiates **PCIe 4.0
×16**, which B450 boards are not supposed to do — AMD withdrew that support from
the 400 series. It trained cleanly through all three equalisation phases with no
errors logged.

## The physics: bandwidth is the whole story

Generating a token requires reading every active weight, once. It is a
memory-bandwidth problem, not a compute problem:

```
tokens/sec ≈ effective memory bandwidth ÷ bytes read per token
```

DDR4-3200 in dual channel gives 2 × 8 bytes × 3200 MT/s = **51.2 GB/s**
theoretical. Real-world efficiency lands around 70%, so budget ~35 GB/s. That
single number predicts everything:

| Model | Size at 4-bit | Read per token | Estimated tok/s |
|---|---|---|---|
| 8B dense | 4.9 GB | 4.9 GB | ~7 |
| 32B dense | 19 GB | 19 GB | ~1.8 |
| 70B dense | 42 GB | 42 GB | ~0.8 |

Notice that a 70-billion-parameter model is hopeless regardless of how much
memory you install. Capacity lets you *load* it; bandwidth decides whether it is
usable.

An aside worth stating because it cost me an assumption: the 5800X3D's 96 MB of
stacked cache — the feature that made it a famous gaming chip — does **nothing**
here. Weights stream through once per token with no reuse, so they blow straight
past any cache. For this workload it performs like an ordinary 5800X.

## Why mixture-of-experts changes the question

For a dense model, size and speed are the same number. For a
[mixture-of-experts (MoE)][moe] model they separate:

- **Total parameters** → how much memory you need
- **Active parameters** → how many bytes are read per token, so how fast it runs

`gpt-oss-120b` has 117 billion total parameters but activates only **5.1 billion
per token**. It needs ~60 GB of memory and reads roughly what a 5B model reads:

| Model | Total | Active | Size | Estimated tok/s |
|---|---|---|---|---|
| `gpt-oss-20b` | 21B | 3.6B | ~12 GB | ~12–15 |
| Qwen3-30B-A3B | 30B | 3.3B | ~18.6 GB | ~15–20 |
| **`gpt-oss-120b`** | 117B | **5.1B** | ~60 GB | **~10–15** |
| Llama 4 Scout | 109B | 17B | ~60 GB | ~3–4 |
| Qwen3-235B-A22B | 235B | 22B | 142 GB | ~1.5 |

The last two rows are the lesson: **active parameter count, not size, decides
usability.** Two models of similar size differ fourfold.

## The RAM question, and why the answer was no

The obvious move was more memory. DDR4 prices have roughly tripled since late
2025 as manufacturers divert capacity to high-bandwidth memory for AI servers, so
a 2 × 32 GB kit runs ~2000 zł. I evaluated seven offers. All of them lost, for
four separate reasons:

**More RAM cannot make anything faster.** Every DDR4-3200 kit lands on exactly
the 51.2 GB/s that the BIOS setting provides for nothing.

**128 GB would make the machine slower.** The board has two slots, so 128 GB
means a four-slot board and four dual-rank modules — **eight [memory
ranks][rank]**. AMD's platform guidance is explicit that more than four ranks
degrades achievable speed; expect a drop to 2400–2667 MT/s. That penalty applies
to every model you run daily, in exchange for one you would rarely tolerate.

**The bigger model isn't better.** Benchmarks put `gpt-oss-120b` ahead of
Qwen3-235B-A22B-Instruct on most tests while being half the size and four times
faster per token. The 235B "Thinking" variant does win on coding and long-context
reasoning — but it is a reasoning model that emits long internal chains, and at
3 tok/s a 2000-token reasoning pass costs eleven minutes before the answer
starts. The quality advantage and the unusability arrive together.

**Buying half now and half later doesn't work.** DDR4 new production ended
through 2026 — Samsung and SK hynix have wound down, Micron serves only
long-lifecycle industrial customers. Future supply is channel inventory and the
used market. Worse, manufacturers change memory chips under an unchanged part
number, and kits are validated as sets, so "the same model" in two years may
simply refuse to train at a usable speed with the pair you already own.

## Is the platform a dead end?

Terminally, for expansion. Socket AM4 is finished, this CPU tops it, DDR4 is
end-of-life, and bandwidth is permanently capped at 51.2 GB/s. A newer chipset
changes nothing — on AM4 the memory controller lives in the CPU, and the
graphics slot's lanes come straight from it, so the chipset is not in the
inference path at all.

But the useful framing isn't "dead end or not". It's **what survives the
platform**:

| Purchase | When the platform is eventually replaced |
|---|---|
| GPU | **Transfers** |
| Power supply | **Transfers** |
| Case, storage | **Transfers** |
| RAM, motherboard, CPU | **Stranded** |

2000 zł spent on a graphics card buys an asset that outlives the machine. The
same 2000 zł spent on DDR4 buys capability that dies with it. That table decided
more than any benchmark.

There is also a nice irony in the existing hardware: the four-year-old graphics
card has **224 GB/s** of memory bandwidth — five times the system RAM. The
bottleneck was never the platform. It was that 4 GB of VRAM is too small to hold
anything useful, so the fast memory sits unused.

## First answer: renting is 12× cheaper

Here is where I expected to conclude "buy the hardware" and did not.

`gpt-oss-120b` on OpenRouter costs **$0.03 per million input tokens and $0.17 per
million output**. Now price the same tokens from a wall socket. Polish
electricity in 2026 runs ~1.13 zł/kWh including distribution. A system under
inference load draws ~500 W:

| | |
|---|---|
| One hour under load | 0.5 kWh × 1.13 zł = **0.57 zł** |
| Tokens produced at ~20 tok/s | ~72,000 |
| Same tokens, rented | 0.072M × $0.17 = **0.045 zł** |

**Generating those tokens locally costs about twelve times more in electricity
alone** — before counting a złoty of hardware. The capital cost cannot pay back,
because the thing it replaces is very nearly free.

So the first answer was: don't self-host. Open-weight models are so cheap to rent
that owning the hardware is a worse deal than the electricity to run it.

## Second answer: photovoltaics narrow it, but don't close it

Add PV to the picture and the arithmetic shifts. Under Poland's net-billing
regime, self-consumed solar energy is **not free** — its cost is the export
revenue you forgo, which is the monthly market reference price (RCEm) times the
1.23 correction factor introduced in February 2026.

The seasonality helps: RCEm collapses precisely when PV peaks, because every
producer exports at once and the market price craters. It was around
**0.19 zł/kWh in March 2026**, making midday surplus cost ~0.23 zł/kWh — roughly
a fifth of grid price.

| | Grid | On PV surplus |
|---|---|---|
| One hour under load | 0.57 zł | **~0.10 zł** |
| Rented equivalent | 0.045 zł | 0.045 zł |
| Ratio | ~12× | **~2×** |

Better, and at these absolute numbers a 2× difference on fractions of a grosz is
noise. But it does not reverse the conclusion. Strictly, converting 0.23 zł/kWh
of export revenue into locally generated tokens produces about 0.09 zł/kWh of
rentable-equivalent value — measured in tokens alone, still value-destroying.

What PV genuinely changes is that the machine becomes **free to run for nine
months a year**, which strengthens the non-financial reasons: privacy,
unmetered experimentation, no per-token accounting.

## Third answer: I measured what I actually run

Then I looked at the dashboard instead of reasoning about it, and both earlier
conclusions collapsed.

I had assumed my API spend went to frontier models — the expensive kind local
hardware cannot replace. It does not. Over one month:

| Metric | Value |
|---|---|
| Spend | **$41.08** |
| Requests | 121,000 |
| Token volume | **406 million** |
| **Blended cost** | **$0.10 per million tokens** |

Ten cents per million is open-model pricing. I was already routed onto cheap
models; there was no optimisation left to find. And 406M tokens across 121K
requests — about 3,400 tokens per request — is not chat. It is a batch pipeline I
run that classifies text and images through OpenRouter models.

The model breakdown mattered more than the total. All-time spend:

| Model | Spend | Share |
|---|---|---|
| **Qwen3-VL-32B-Instruct** (vision) | **$35.70** | 65% |
| Mistral Small 3.2 24B | $13.83 | 25% |
| Everything else (23 models) | $5.57 | 10% |

**Ninety percent of my spend is two open-weight models of 24 and 32 billion
parameters — exactly the size a 24 GB graphics card runs locally.** The premise
of the first two answers was simply false.

### The database disagreed with the invoice

The pipeline records every call in PostgreSQL, so I cross-checked. Over three
weeks: 88,429 calls, $40.05 recorded. Two discoveries:

**Two billing rails.** One model route bills its vendor directly rather than
through OpenRouter — $21.35 that never appears on the dashboard. True spend was
~$76, not $55.

**Two thirds of API spend had no database row.** The vision model showed $35.70
on the invoice and $1.88 in my own table. The dates explained it: recorded vision
calls existed on four days, while the invoice's largest spikes fell on two days
with *no recorded calls at all* — runs started by hand that spent the key without
writing telemetry. My cost tracking was blind to its most expensive stage.

That is the kind of error you only find by comparing two independent records,
and it is a good argument for keeping both.

### Which makes the hardware case

A 32-billion-parameter vision-language model at 4-bit quantisation is ~19–20 GB
of weights **plus** a vision encoder. That does not fit in 16 GB. **The optical
character recognition (OCR) requirement single-handedly settles the card size at
24 GB.**

Projecting a sustained 3,000 vision calls per day:

| | Monthly |
|---|---|
| GPU time required | ~137 hours (~4.6 h/day) |
| Rented | ~300 zł |
| Local electricity, on PV surplus | **~16 zł** |
| Payback on a ~4000 zł card | **~14 months** |

The workload is throughput-oriented, tolerant of latency, and already runs in
batches. It is close to the ideal case for owning hardware — and it is the
opposite of the chat workload I had been modelling.

The general lesson: **cheap model plus slow local inference means rent; costly
model plus efficient local inference means host.** The ratio between them is
workload-specific and inverts.

## Where does the heat go?

One more cost that does not appear on any invoice. A computer converts
essentially all of its electrical draw into heat, so 500 W for three hours puts
1.5 kWh into a room.

I have access to a calibrated multi-zone thermal model of a well-insulated house
near Poznań — six zones fitted against a year of sensor data, 0.60 °C calibration
error. Borrowing one 12 m² ground-floor room from it gives a realistic answer,
using a [lumped-capacitance][lumped] model:

```
C · dT/dt = P − U · ΔT        ΔT(t) = (P/U) · (1 − e^(−t·U/C))
```

With the fitted parameters — 7.50 MJ/°C of thermal mass, 4.00 W/°C to outdoors,
5.03 W/°C of ventilation before 83% heat recovery, and 155 W/°C of conduction
into neighbouring rooms:

| Hours | Room | Whole house |
|---|---|---|
| 1 | +0.23 °C | +0.06 °C |
| **3** | **+0.64 °C** | +0.18 °C |
| 6 | +1.15 °C | +0.35 °C |
| 12 | +1.88 °C | +0.69 °C |

**97% of the heat leaves sideways into the rest of the building**, not outdoors.
An interior room cannot get very hot on its own — it shares the heat with the
house. Steady state would be +3.13 °C, but the time constant is 13 hours, so a
work session never approaches it. For intuition: 500 W is about five adults
sitting in the room.

And in winter that heat is not waste. It displaces heat a heat pump would
otherwise produce — at a coefficient of performance of 3.5, 1.5 kWh of heat saves
~0.43 kWh of electricity, worth ~0.48 zł. That **exceeds** the ~0.35 zł of PV
surplus the run consumed. In winter, on solar, the compute is free and the
heating is a bonus. In summer with active cooling it reverses, costing ~0.56 zł
to pump the same heat back out.

## What I'm actually going to do

| Decision | Answer |
|---|---|
| Enable XMP and Resizable BAR | Yes — free, and first |
| Reinstall the operating system | Yes — the stack is five years stale |
| Buy RAM | **No.** These models live in VRAM; 32 GB is sufficient |
| Buy a motherboard | **No.** Zero inference gain |
| Buy a GPU | **Yes — 24 GB, ~4000 zł** |

Target configuration:

| Component | Now | Planned |
|---|---|---|
| CPU | Ryzen 7 5800X3D | unchanged |
| RAM | 32 GB @ 2667 | 32 GB @ **3200** (BIOS only) |
| GPU | RX 5500 4 GB | **24 GB card** |
| PSU | unknown | ~850 W |
| Serving | — | batched inference server, not single-stream |

I'll favour a CUDA card over the AMD equivalent, despite near-identical VRAM,
bandwidth and price. Batch serving means [vLLM][vllm], whose CUDA path is far
better trodden than its ROCm one — and my current card is itself a demonstration
of that risk, since RDNA1 never got ROCm support at all, which is why 224 GB/s
of memory bandwidth sits idle in the case.

Two things I have not done and should before spending: measure batched
throughput rather than trusting my arithmetic, and validate 4-bit vision quality
against existing results. Quantised vision-language models are not the same
artifact as the hosted weights, and OCR is precision-sensitive. I have tens of
thousands of graded calls to regression-test against, which is a better position
than most.

## Renting the card before buying it

Both of those unknowns are answerable for about a dollar. An RTX 3090 rents for
**$0.22/hour** on [RunPod][runpod]'s community cloud — the same card I was
considering, so the numbers transfer directly. Here is the whole procedure,
including the parts that went wrong.

### Create the pod

Ask for the card you would actually buy. Renting an A100 proves nothing about
whether a model fits in 24 GB.

- **GPU:** RTX 3090, community cloud
- **Image:** an official `runpod/pytorch:*-cu128-*` image. These install your
  public key into `authorized_keys` and start `sshd`; a bare vLLM image may not,
  and SSH is what carries the port-forward later.
- **Volume:** 100 GB mounted at `/workspace`. This survives stop/start — the
  reason it matters is below.
- **Ports:** `22/tcp` and `8000/http`
- **SSH key:** paste the *contents* of `~/.ssh/id_ed25519.pub`

Use the **direct** SSH address (`ssh root@<ip> -p <port>`), not the proxy — the
proxy is unreliable for port forwarding.

### Install the server, on the volume

Both the Python environment and the model cache must live on `/workspace`, or
stopping the pod throws away a 20 GB download and a five-minute install:

```sh
export HF_HOME=/workspace/hf
uv venv /workspace/venv --python 3.12
uv pip install --python /workspace/venv/bin/python vllm
```

Two traps here. `pip install` fails outright with `externally-managed-environment`
([PEP 668][pep668]) — but `uv` is already on the image, so there is nothing to
install first. And when you launch the server, **put the venv on `PATH`**:

```sh
export PATH=/workspace/venv/bin:$PATH
```

Skip that and `torch.compile` cannot find `ninja` — which *is* installed — and
the engine dies with a `FileNotFoundError` that looks nothing like a path
problem.

### Pick a checkpoint that actually fits

A 24 GB card has **23.56 GiB usable**, and you need 2–3 GiB above the weights
for activations. Check the real size before renting anything, because parameter
arithmetic underestimates:

```sh
curl -s "https://huggingface.co/api/models/<repo>?blobs=true" | python3 -c "
import json,sys; m=json.load(sys.stdin)
print(round(sum(f.get('size') or 0 for f in m['siblings'])/1e9,1),'GB')"
```

On an Ampere card (the 3090) you want **AWQ or GPTQ**. FP8 needs Ada or Hopper;
NVFP4 needs Blackwell. Neither will run.

### Start it

```sh
vllm serve <repo> \
  --max-model-len 8192 --max-num-seqs 16 \
  --enable-prefix-caching \
  --gpu-memory-utilization 0.92 \
  --port 8000 --host 0.0.0.0
```

Do **not** pass `--quantization awq` reflexively. Several repacks labelled AWQ
are actually `compressed-tensors`, and vLLM detects the format correctly when
you leave the flag off.

Watch the startup log for two numbers that answer the questions you came for:

```
GPU KV cache size: 37,504 tokens
Maximum concurrency for 8,192 tokens per request: 4.58x
```

The first tells you whether the model fits with room to work. The second is the
concurrency ceiling — and since throughput is the entire economic case for
owning hardware, it matters more than the model size.

### Use it exactly like the hosted API

This is the part that makes the whole exercise cheap. vLLM speaks the
OpenAI-compatible protocol, so an existing client needs a different base URL and
nothing else. Forward the port over SSH rather than exposing the server:

```sh
ssh -N -L 8000:localhost:8000 root@<pod-ip> -p <pod-port>
```

Then point the client at it:

```sh
export MY_LLM_BASE_URL=http://localhost:8000/v1
export MY_LLM_API_KEY=local-test
```

My own pipeline reads its endpoint from an environment variable and already
sends OpenAI-shaped requests, so switching from a hosted provider to a rented
GPU was two exports and no code change. If yours hardcodes a URL, that is the
one thing worth refactoring before you start.

### What went wrong, so you can skip it

Roughly 45 minutes of the session went to environment problems rather than
measurement:

| Symptom | Cause |
|---|---|
| `externally-managed-environment` | PEP 668; use a venv, and don't install `uv` — it's already there |
| `FileNotFoundError: 'ninja'` | venv `bin` missing from `PATH` |
| `Free memory (1.62/23.56 GiB) is less than desired` | a killed server left `EngineCore` holding VRAM. Kill by GPU ownership: `nvidia-smi --query-compute-apps=pid --format=csv,noheader \| xargs -r kill -9` |
| A liveness check reporting `RUNNING` when nothing ran | `pgrep -f "vllm serve"` matches its own command line. Use `pgrep -f "[v]llm serve"` |
| A start script that silently never existed | a heredoc inside a compound SSH command vanished without error. Pipe it through ssh's stdin and verify with `wc -l` before launching |

### Two findings worth the rental on their own

**The 32B vision model I wanted to run does not fit a 24 GB card.** Its weights
alone are 20.98 GiB of 23.56 GiB usable — out of memory before any KV cache, in
two different configurations. Every throughput and payback number I had
calculated assumed sixteen concurrent requests on a model that cannot serve one.
That is the entire purchase case, dismantled for about six cents.

**Community quantisations are much rougher than the hosted endpoint they
replace.** Of four checkpoints tried: one did not fit, one had a broken image
processor, the same one shipped without a chat template *and* triggered a
tokenizer backend that made the template un-overridable. The fourth worked
first try. Every locally-served model is somebody's repack, and that packaging
labour is a real cost of self-hosting that never shows up in a price-per-token
comparison.

### And one process mistake

I launched a 1,000-request batch that failed 1,000 times with the same error —
the client's default `max_tokens` of 32768 exceeded the server's 8192 context.
A single request would have shown it in three seconds. Failures at this layer
are uniform, so scale adds no information whatsoever. **Send one call, read the
response body, then scale.**

## The method note

Three answers, two wrong, and the corrections came from measurements rather than
better thinking: `dmidecode` found the underclocked memory, the billing dashboard
found the false premise, and the database found the missing telemetry.

The pattern is worth naming, because I keep relearning it. Each wrong answer was
perfectly reasoned from an assumption I had not checked — that my spend went to
expensive models, that a chat workload was the relevant one. The reasoning was
never the weak link. **The unexamined input was.**

[xmp]: https://en.wikipedia.org/wiki/Extreme_Memory_Profile
[rebar]: https://en.wikipedia.org/wiki/PCI_configuration_space#Resizable_BAR
[moe]: https://en.wikipedia.org/wiki/Mixture_of_experts
[rank]: https://en.wikipedia.org/wiki/Memory_rank
[lumped]: https://en.wikipedia.org/wiki/Lumped-element_model
[vllm]: https://github.com/vllm-project/vllm
[runpod]: https://www.runpod.io/
[pep668]: https://peps.python.org/pep-0668/
