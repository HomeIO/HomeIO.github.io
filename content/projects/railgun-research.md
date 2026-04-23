---
title: 'RailgunSim.jl'
date: 2026-04-22
draft: true
topics: ['physics']
tags: ['simulation', 'electromagnetism', 'julia', 'gpu', 'optimization', 'fem']
tech: ['Julia', 'Metal.jl', 'DiffEqGPU', 'ForwardDiff', 'Ferrite', 'CairoMakie']
description: 'GPU-accelerated electromagnetic railgun simulation. 7-state ODE with coupled EM, thermal, and mechanical physics. Gradient-based design optimization improves muzzle velocity by 460%. Apple Silicon GPU parameter sweeps at 50–200× speedup. 2D FEM validation.'
status: 'completed'
---

`~/projects/llm/military/railgun-research` · 657 tests · Julia 1.10

## Goal

Understand what it takes to design a functional electromagnetic railgun — not from armchair speculation, but from first-principles physics. The project couples circuit electromagnetics, thermal dynamics, structural mechanics, and material science into a single simulation pipeline. Then it asks: given this physics, what is the best possible design?

## Approach

### Physics model

A 7-state ODE system models the full firing sequence — capacitor discharge through parallel rails, Lorentz force acceleration, Joule heating, and temperature-dependent resistance:

| State | Description | Governing equation |
|-------|-------------|-------------------|
| I(t) | Circuit current | KVL: L(x)·dI/dt = V_cap − I·R − L'·v·I |
| v(t) | Projectile velocity | Lorentz: m·dv/dt = ½·L'·I² |
| x(t) | Position | dx/dt = v |
| T_rail(t) | Rail temperature | dT/dt = I²·R_rail / (m·cp) |
| T_proj(t) | Projectile temperature | dT/dt = I²·R_contact / (m·cp) + friction |
| V_cap(t) | Capacitor voltage | dV/dt = −I/C |
| R_total(t) | Total resistance | dR/dt from thermal + positional changes |

The model evolves through several versions. v2 added skin effect, thermal expansion stress, magnetic repulsion bending, erosion, and cost modeling. v3 added the solid→plasma contact transition, velocity skin effect, and post-muzzle external ballistics. v4 introduced CuCrZr (C18150) weapon-grade copper alloy with realistic yield strength, material-aware penalty functions, and weapon-scale design bounds.

### Finding 1: Material selection dominates performance

The single most impactful discovery was switching from OFHC copper (annealed, σ_yield = 69 MPa) to CuCrZr alloy (σ_yield = 400 MPa). The weak copper yields under thermal expansion stress after just ~18 K temperature rise, making thermal stress the binding constraint on velocity. CuCrZr raises that limit to 101 K and removes thermal stress as a bottleneck entirely — increasing achievable velocity by ~40%.

This is not a subtle optimization. It is the difference between a railgun that works and one that destroys itself on the first shot.

### Finding 2: Skin effect increases resistance by 3.9×

At the baseline design's LC frequency (~1492 Hz), the skin depth is just 1.69 mm — smaller than the rail thickness. Current concentrates on the inner surfaces facing each other, increasing effective rail resistance by 292% compared to the DC-resistance model.

The optimization naturally pushes designs to lower frequencies (~957 Hz) where skin depth increases to 2.11 mm and the correction factor drops to ~1.9–4.0×. But the skin effect is never negligible. Any railgun design that ignores it is off by nearly a factor of four in resistance.

### Finding 3: Gradient-based optimization finds non-obvious designs

Starting from a naive baseline (162.6 m/s), L-BFGS with ForwardDiff through the ODE solver finds a velocity-optimized design at **910.8 m/s** — a **+460% improvement** in 25 seconds.

The optimized design is counterintuitive:

| Parameter | Baseline | Optimized | Why it works |
|-----------|----------|-----------|--------------|
| Voltage | 5,000 V | 1,229 V | Lower V₀ + higher C_bank = longer pulse, more efficient energy transfer |
| Capacitance | 10 mF | 23.8 mF | More stored energy, slower discharge |
| Rail separation | 20 mm | 100 mm | Wider rails → more force (F ∝ L'·I²), longer effective barrel |
| Rail length | 1.0 m | 0.3 m | Shorter but wider barrel; geometry trades differently than intuition suggests |
| Projectile mass | 10 g | 1.0 g | Lower mass → higher velocity; stress constraints permit this with CuCrZr |
| Rail thickness | 5 mm | 50 mm | Thick rails handle magnetic repulsion (355.7 MPa, 89% of yield) |

The cost-optimized design (max KE/$) converges to a similar geometry but with slightly higher mass and voltage, achieving 889.5 m/s at half the system cost of the velocity-optimal design.

![Velocity-optimized trajectory showing current, velocity, position, and temperature over the 3.6 ms firing sequence](/img/projects/railgun-research/trajectory.png)

### Finding 4: The Pareto front is sparse — cost and performance are tightly coupled

A 1600-point GPU parameter sweep reveals that most intermediate designs are dominated. The Pareto front between velocity and cost has only a few distinct points:

- **Min cost:** 105 m/s, $4,651
- **Knee point:** 402 m/s, $9,723 (the "sweet spot")
- **Max velocity:** 911 m/s, $21,616

There is no cheap way to get high velocity, and no expensive way to get much beyond 911 m/s given the physics constraints. The strong coupling suggests that railgun design is fundamentally about choosing which constraint to relax — not about finding clever trade-offs.

![Pareto front showing velocity vs. system cost with dominated designs in gray](/img/projects/railgun-research/pareto.png)

### Finding 5: GPU acceleration is 50–200× faster, and Float32 is sufficient

All ensemble work runs on Apple Silicon GPU via Metal.jl. A 1600-trajectory parameter sweep completes in seconds instead of minutes. The key validation: Float32 vs Float64 relative error stays below 0.1% — well within engineering tolerance.

Apple Metal has no hardware Float64, so this is not an option — it is a constraint. The solution is careful tolerance selection (abstol=1e-5, reltol=1e-3) and explicit validation against CPU Float64 reference.

### Finding 6: Contact physics limit the model at ~1000 m/s

Below ~1000 m/s, the armature maintains solid metal-metal contact with the rails. Above that, it transitions to a plasma arc — the model breaks down because ablation physics are not included. For the optimized designs (910 m/s and 889 m/s), the armature is still in solid contact, but close to the transition threshold. The velocity skin effect (current concentration on the trailing edge at high speed) is already significant — a 5.7–5.8× resistance increase from magnetic Reynolds number effects.

This defines the model's validity envelope: the designs are near but not beyond the edge of what this physics can predict.

### Finding 7: Sensitivity reveals the design levers

Forward-mode automatic differentiation through the ODE solver gives exact parameter sensitivities. The rankings are consistent across all designs:

| Rank | Parameter | Elasticity | Meaning |
|------|-----------|-----------|---------|
| 1 | Projectile mass | −1.4 to −1.0 | Halve mass → ~40% more velocity |
| 2 | Rail length | +0.8 to +1.4 | Longer barrel → more acceleration distance |
| 3 | Initial voltage | +0.5 to +1.0 | Diminishing returns at high V₀ |
| 4 | Capacitance | +0.3 to +0.8 | Matters more when optimized |
| 5 | Rail separation | +0.1 to +0.5 | Wider → more force, but more resistance |

Mass and length dominate. Voltage and capacitance matter, but their elasticities are lower than intuition might suggest.

![Sensitivity analysis showing ∂v/∂x for all 8 design parameters](/img/projects/railgun-research/sensitivity.png)

### FEM validation

A 2D magnetostatic FEM solve (Ferrite.jl) extracts the inductance gradient L' from first-principles field geometry. Comparing against the analytical approximation shows agreement within a few percent across aspect ratios. The FEM confirms that the lumped-circuit L' model is reasonable for the geometry range explored.

![2D FEM magnetostatic field solution showing B-field lines around the rail-armature geometry](/img/projects/railgun-research/fem-field.png)

### Cost reality check

The railgun shot cost is ~$0.10–$0.50 per round (amortized). Compared to conventional munitions:

| Munition | Unit Cost | Railgun ratio |
|----------|-----------|---------------|
| Railgun shot | ~$0.50 | 1× |
| 155mm HE shell | $1,500 | ~3,000× costlier |
| Tomahawk cruise missile | $1.9M | ~4,000,000× costlier |

The cost advantage is staggering — if the physics can be made reliable. The US Navy railgun program targeted $25,000/shot at 2000–2500 m/s. This simulation suggests the cost floor is far lower, but the velocity ceiling (without plasma transition) is ~900–1000 m/s.

## Outcome

- **657 tests** covering physics, GPU validation, optimization convergence, sensitivity correctness, and FEM accuracy
- **7-state ODE** with v2–v4 physics additions: skin effect, thermal expansion, magnetic repulsion, erosion, contact transition, velocity skin effect, external ballistics
- **460% velocity improvement** from gradient-based optimization (162 → 911 m/s)
- **50–200× GPU speedup** for ensemble sweeps, validated at <0.1% error vs Float64
- **Pareto front** revealing sparse, strongly-coupled cost-velocity trade space
- **2D FEM validation** confirming analytical L' model
- **Sensitivity rankings** showing mass and rail length as dominant design levers

## What I learned

- **ForwardDiff through an ODE solver just works.** The gradient of muzzle velocity with respect to 8 design variables, computed through a 7-state Tsit5 solve with adaptive stepping, is exact and costs ~8× a forward pass. No finite differences, no manual adjoints.
- **Material properties are often the binding constraint.** The difference between 69 MPa and 400 MPa yield strength changed everything about what the design could achieve. Physics codes need real material data, not idealized assumptions.
- **Float32 on GPU is viable for engineering simulation** — but only with explicit validation. The 0.1% error bound was not assumed; it was measured against Float64 on every script.
- **The Pareto front being sparse was surprising.** I expected a smooth curve of trade-offs. Instead, most designs are dominated, and the frontier has only a few distinct regimes. This suggests railgun physics has sharp constraint boundaries, not gentle trade-offs.
- **CuCrZr came from ITER fusion research.** The same copper-chromium-zirconium alloy used in tokamak divertors handles extreme thermal and mechanical stress. Cross-domain material knowledge matters.

## Model Validity

This simulation applies to **solid-armature railguns with muzzle velocities below ~1000 m/s**. The 7-state ODE assumes solid metal-metal contact between armature and rails, with Ohmic contact resistance and a well-defined Lorentz force.

Above ~1000 m/s, the armature transitions to a **plasma arc** — ablated aluminum vapor conducting current through a plasma sheath. This regime requires ablation physics, MHD pressure modeling, restrike dynamics, and shot-to-shot geometry evolution from rail erosion. These are not included here.

The optimized designs (910 m/s and 889 m/s) sit near but within the valid regime. The model does not predict performance beyond the plasma transition threshold.

**Why this boundary is the end of this simulation:** Adding plasma-armature physics would require a fundamentally different model — 1D or 2D MHD with species transport, radiative cooling, and ablation mass injection. Runtime per trajectory would increase from milliseconds to minutes or hours. The GPU ensemble pipeline would no longer apply. And validation would require experimental data that does not exist in the open literature. This is a research frontier, not an engineering extension.

## Stack

- **Julia** — physics ODE, optimization, sensitivity, uncertainty quantification
- **OrdinaryDiffEq + Tsit5** — adaptive ODE solver
- **ForwardDiff** — forward-mode AD through ODE for gradients
- **Optimization.jl + L-BFGS** — gradient-based design optimization
- **Metal.jl + DiffEqGPU** — Apple Silicon GPU ensemble sweeps
- **Ferrite.jl** — 2D FEM magnetostatic validation
- **CairoMakie** — publication-quality plotting
