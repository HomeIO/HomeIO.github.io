---
title: "Heating the Same Water Twice: What a Water Dispenser Actually Saved"
date: 2026-09-03
draft: true
tags: ["energy", "home-assistant", "measurement", "appliances", "sendom"]
description: "A relative bought a hot-water dispenser to stop wasting electricity on the kettle. The kettle's meter promptly dropped 40 %. The catch: the dispenser is fed by the kettle, so the water is now heated twice — and the first heating is thrown away in full. Here is what the numbers say, and the measurement trap that nearly turned a network outage into a success story."
topics: ["energy", "home-automation"]
math: true
---

A relative of mine bought a hot-water dispenser for the kitchen — one of those 2.5 kW heat-on-demand units with a variable tap, anywhere from 40 to 100 °C. The reasoning was the reasoning everybody has: a kettle boils a litre and a half to make one cup of tea, the rest goes cold, and later somebody boils it again. A dispenser heats only what you pour. Obviously that saves energy.

The kettle sits on a metered smart plug, so the claim is testable. Five months of before, three weeks of after.

The kettle's consumption fell **40 %**. And that number is almost meaningless. Here is why.

---

## The Chain Nobody Draws on the Box

The dispenser is not plumbed in. It has a **2.7 L tank** that gets filled by hand, plus a separate ~3 L vessel where water waits to cool down. And the water that goes in is not tap water — it is **boiled** water, because the household boils drinking water for safety. Boiled in the kettle. Then left to cool to room temperature. Then poured into the tank. Then reheated by the dispenser, on demand, to somewhere between 40 and 100 °C.

Read that again as an energy path:

```
tap water ──kettle──> 100 °C ──cools to 25 °C──> tank ──dispenser──> 75 °C cup
                                    ▲
                        every joule of this is thrown away
```

The water is heated twice, and the **first heating is discarded in full**. This is not a replacement for the kettle. It is an appliance the kettle feeds.

So the saving — if any — cannot come from the physics of the chain. Per litre delivered, the chain is strictly worse:

| Stage | ΔT | Wh per litre |
|---|---|---|
| Kettle: mains 18 °C → 100 °C, η ≈ 0.95 | 82 K | **99.9** |
| Cool to room temp 25 °C | −75 K | *discarded* |
| Dispenser: 25 °C → 75 °C, η ≈ 0.97 | 50 K | **60.2** |
| **Total, two-stage** | | **160.1** |
| *For comparison: straight from the kettle* | | *99.9* |

**+60 % per litre.** At a 90 °C tap it is +78 %. There is no dispense temperature at which heating water twice beats heating it once.

And yet the meter says the kettle uses 40 % less. Both of those things are true at the same time, and the reason is the whole point of this post.

## Volume, Not Efficiency

The dispenser does not make hot water cheaper. It makes the household **need less of it**.

![Kettle electricity with a 7-day rolling mean](/img/posts/sendom-heating-water-twice/113_rolling_usage.png)

| Period | | kWh/day | litres/day |
|---|---|---|---|
| Kettle A | Mar 27 – May 27 | 0.731 | 6.8 |
| Kettle B | May 28 – Aug 2 | **0.653** | **6.4** |
| Dispenser era | Aug 10 – Sep 3 | **0.391** | **3.9** |

The litres boiled fell by **39 %**. Not because anybody drinks less tea, but because the water that used to go cold in the kettle now sits in a tank and gets reheated a cup at a time instead of a litre at a time.

The per-boil numbers confirm it. Boil *size* barely moved — 0.84 L before, 1.03 L after. What collapsed was **frequency**: 7.9 boils a day down to 4.0.

![Hour-of-day shift and per-boil size distribution](/img/posts/sendom-heating-water-twice/113_usage_shift.png)

And it collapsed selectively. Morning boils largely survived; the **evening ones nearly vanished** (18:00 went from 40 Wh/day to 7). That is exactly the signature you would predict: the 21:00 cup of tea no longer needs a kettle, but filling the tank still does.

So two effects pull against each other — **+60 % per litre, −39 % litres** — and they very nearly cancel. Run the arithmetic across the full range of tap settings and you get an actual break-even:

![Break-even sweep over dispense temperature](/img/posts/sendom-heating-water-twice/113_breakeven.png)

**Break-even lands at ~80 °C.** Below that the chain wins; above it, it loses. The household's stated setting for green tea is 70–80 °C — which means this entire investment sits, by coincidence, almost exactly on the line where it stops mattering.

I want to be honest about the uncertainty: the dispenser's own meter was only installed on the last day of this analysis, so **stage 2 is predicted from physics, not measured**. The stage-1 numbers are measured. The break-even point depends on the actual mix of tap temperatures, which nobody logs. A week of the new sensor settles it.

## The Trap: An Outage That Looks Like a Saving

This is the part worth stealing regardless of whether you own a kettle.

Home Assistant's export for this house contains **only numeric states**. When a Zigbee plug drops off the network, its state becomes `unavailable`, and `unavailable` does not survive the export. It just isn't there.

Which means an offline plug and an unused appliance produce *identical* data: nothing.

Sum power over time and every network outage is scored as **0 kWh used**. Not as missing. As *saved*. The analysis silently manufactures the result you were hoping for, which is the most dangerous kind of bug.

It happened twice here. The household was away in early August, and the plug also went offline for four days at the end of the month. Left uncorrected, those days read as a triumph — at one point it looked like the kettle had been **retired entirely**.

The obvious fix — "flag suspiciously long gaps" — does not work, and the reason is instructive. The plug's reporting behaviour *changed mid-series*. In April it reported power **on change only**, so a genuinely idle, perfectly healthy plug went silent for ten hours at a stretch. By September a firmware or config change had added an hourly heartbeat. A fixed max-gap rule flags April as broken and September as fine. **Exactly backwards.**

What works: **the plug's voltage channel as a liveness beacon.**

Mains voltage drifts continuously. A healthy plug therefore reports it 8–12 times an hour *whether or not the appliance is used*, with no day/night pattern (measured: 8/h at 03:00, 12/h at 14:00). A degraded plug drops to ~1/h. An absent one reports nothing.

The two modes turn out to be cleanly separated. Across 3864 hours of this plug's history, **not a single hour falls between 2 and 3 readings per hour**. The threshold isn't a judgement call — the data leaves an empty corridor and you put the line in it.

An hour counts as observed if it carries ≥3 voltage readings. Unobserved hours contribute nothing *and leave the denominator*. Days below 80 % coverage become missing, never zero. The rolling mean requires 5 valid days out of 7, so the line **visibly breaks** across an outage rather than quietly interpolating across it.

![Period comparison and daily plug availability](/img/posts/sendom-heating-water-twice/113_periods.png)

Nine days got excluded. Without that, the headline saving would have been overstated — and the most exciting finding in the dataset would have been a Zigbee dropout.

## Two Details the Data Volunteered

**The kettle was swapped and nobody mentioned it.** On 2026-05-28 the peak draw steps from ~2850 W to ~2120 W overnight and never recovers. A resistive element draws `P = V²/R`, so less power means either lower voltage or a different element — and plug voltage *rose* over the same period, 237 → 243 V. So: different kettle. It doesn't change energy per litre (same water, same ΔT — the new one is just slower), but it splits the baseline into two appliances, which is why there is a "Kettle A" and a "Kettle B" above.

**Tap water is not a constant, and it matters here.** Polish mains swings about 9 K over the year, and this measurement window — late March to early September — sits almost exactly on the rising limb. Assume a flat 15 °C and you understate spring litres and overstate summer ones, biasing the *specific comparison* the whole post rests on. Instead the mains temperature comes from the [Burch & Christensen correlation](https://www.nrel.gov/docs/fy07osti/40772.pdf) (NREL, 2007 — the model behind EnergyPlus and BEopt), driven by 716 days of this house's own outdoor thermometer: **10.1 °C in late March rising to 18.4 °C in early September**, peaking mid-August. That mid-August peak is the physically expected ground-coupled lag behind air temperature, which is a reassuring sign the model is doing something real.

That is a 9 % swing in the energy per litre. Small, but the effect being measured is not enormous either.

## What It Costs, and Who Pays

The household deliberately runs the safety boil during the day, on solar. So a raw kWh comparison is the wrong currency — a kWh boiled while the house is exporting is not worth a kWh boiled at 19:00.

The house meter is *signed*, which makes marginal attribution clean and needs no PV sensor at all. For a load drawing power `P` while the meter reads `G`:

$$E_{grid} = \max(G, 0) - \max(G - P, 0)$$

Exporting? The boil only displaces export, so it is solar-covered. Importing at more than `P`? Fully grid. Everything between handles itself. (This turned out to matter for a boring reason: the PV inverter stopped reporting on August 28th. The signed meter doesn't care.)

![PV versus grid split of the safety boil](/img/posts/sendom-heating-water-twice/113_pv_split.png)

The result is a gentle deflation of the household's own story. The safety boil is **57 % solar-covered before the dispenser and 58 % after**. The intent is real, but the habit did not become *more* solar-timed — and 42 % still comes off the grid.

![Daily cost and the scenario comparison](/img/posts/sendom-heating-water-twice/113_cost_and_scenarios.png)

Priced at wholesale spot, valuing exported energy at spot × 0.8 as the opportunity cost of self-consuming it:

- Kettle only: **0.263 PLN/day**
- Dispenser era: **0.170 PLN/day**
- Saving: **0.093 PLN/day ≈ 34 PLN/year**

Thirty-four złoty a year. The appliance will not pay for itself on energy, ever. (A nice aside: **6–7 % of the boil energy landed at negative prices** — moments when the household was being *paid* to boil water. Those show up as the bars below zero.)

## The Heat Doesn't Disappear, It Just Moves

One cost the electricity meters cannot see: boiled water sitting in an open vessel releases **every joule** of its heat back into the kitchen on the way down to 25 °C. In winter that's a small heating credit. In summer, with the AC running, the house pays twice — once to make the heat, once to pump it out.

Usefully, the sensible/latent split doesn't matter for the energy: water that evaporates off the vessel condenses on the AC coil, so the AC removes it either way.

Measured against the AC circuit meter, weighting each day's rejected heat by the share of that day the AC actually ran, at EER 3.4:

- **363 Wh/day** of heat dumped into the kitchen during the dispenser era
- → **22 Wh/day** of AC electricity to remove it

I had expected this to be a bigger deal than it is. It adds **6 %** on top of the stage-1 meter reading — real, worth knowing, not a headline. (The pre-dispenser figure was 603 Wh/day rejected → 62 Wh/day of AC, so the dispenser did shrink this too.) The honest conclusion is that the effect I went looking for turned out to be minor, and the measurement is worth more than the hypothesis was.

## The Answer Nobody Bought an Appliance For

Step back and total up the whole chain, at a 75 °C tap:

| | kWh/day |
|---|---|
| Stage 1 — safety boil | 0.391 |
| Stage 2 — dispenser reheat *(predicted)* | 0.237 |
| AC removing the cool-down heat | 0.022 |
| **Whole chain** | **0.650** |

Stage 1 is **60 % of everything spent on hot drinking water in this house**. And stage 1 exists to satisfy exactly one requirement: water safety. Not taste, not convenience — safety.

If that requirement were met another way — a filter, on mains water that is tested and treated — the boil disappears, and with it both its electricity and its AC penalty. Stage 2 is untouched; the dispenser still reheats the same litres, just starting slightly colder because the water was never boiled.

**Net saving: 0.384–0.413 kWh/day, or 59–64 % of the entire chain.** Roughly 61–65 PLN/year at the household's blended rate — which is to say, about twice what the dispenser itself achieved.

To be clear about scope: whether a filter is an acceptable substitute for boiling is a *health* question and I have not answered it. This is only the energy side of the ledger. But it reframes the problem usefully. The dispenser optimised the second-largest item in the chain. The largest one was never on the table, because nobody thought of the safety boil as an energy decision at all — it was just what you do.

## What's Still Unmeasured

Stage 2's meter went in on the last day of this analysis. Its first and only data point: **2460 W for 19 seconds**, which at 25 → 95 °C works out to **0.15 L** — one mug. That the arithmetic closes on the very first event is a good omen for the sensor.

Two things activate as soon as it has a week of history:

1. **A mass balance.** Litres boiled versus litres dispensed. This replaces the assumption the whole break-even rests on — that *every* boiled litre passes through the tank — with a measurement. It also back-solves the dispenser's real efficiency instead of assuming 0.97.
2. **Standby.** The unit reported an explicit 0 W when idle, so it probably has none. Worth confirming, because a 45 W phantom load would erase everything above. (There *is* an unexplained +45 W step in the house's night baseload around August 13th — but it lands three days after the dispenser was installed, and it isn't a clean step, so it is more likely the new automation stack than the appliance.)

---

The dispenser was bought to save energy and it does, marginally, for reasons entirely unrelated to the ones on the box. It is not more efficient — it is 60 % *less* efficient per litre. It saves because it changed how much hot water the household needs, and that effect was slightly larger than the penalty for heating everything twice.

Which is the general lesson, and it is not really about kettles. The appliance didn't make anything more efficient; **it made the household's behaviour cheaper to run.** That is a perfectly good reason to buy something. It is just not the reason anybody thinks they are buying it, and you cannot tell the difference without a meter on the plug — plus enough scepticism to notice when the meter has quietly stopped talking to you.
