---
title: 'enea-invoice-analyzer'
date: 2026-04-18
draft: true
topics: ['energy']
tags: ['pdf-parsing', 'energy-billing', 'prosumer', 'home-automation']
tech: ['Python', 'pdfplumber', 'Pydantic', 'Click']
description: 'Structured data extraction from Polish electricity invoices — 50+ fields parsed from ENEA PDF bills with prosumer settlement, tariff handling, and automatic personal data redaction.'
status: 'in-progress'
---

`~/projects/llm/smart-home/enea-invoice-analyzer` · commit `9e22955` (2026-04-18)

## Goal

Turn [ENEA][enea] electricity PDF invoices into structured, machine-readable JSON. Extract every data point that matters for energy analysis — consumption, generation, tariffs, costs, prosumer settlement — while automatically redacting personal information.

## Approach

### PDF parsing pipeline

[pdfplumber][pdfplumber] extracts text from digital PDFs (no OCR needed). Regex-based extractors parse each invoice section — delivery points, meter readings, energy balances, distribution charges, VAT — into [Pydantic][pydantic] models with full type validation.

Handles Polish-specific formats: comma as decimal separator, dot as thousands separator, Polish month abbreviations, DD/MM/YYYY dates.

### Invoice types and tariffs

- **Regular invoices** (FAKTURA VAT) and **corrections** (KOREKTA) with separate settlement models
- **Tariff groups**: C11 (single-zone flat rate) and G12 (day/night two-zone pricing)
- **Prosumer data**: solar generation, [net metering][net-metering] settlement, deposit tracking, energy fed to grid vs consumed

### Data extracted (50+ fields)

- Delivery point details: location, [PPE][ppe] code, tariff, billing period, contracted power, fuse rating
- Meter readings: multiple readings per invoice with dates, values, consumption, method (remote/physical)
- Energy balance: consumed, fed-to-grid, net amounts post-balancing
- Financial breakdown: energy sales, distribution charges (fixed, variable, [RES surcharge][res], capacity, cogeneration, quality fees), excise tax, VAT (23%), payment schedules
- Prosumer deposit: running balance of energy credits

### Privacy and security

Personal data (names, addresses, bank accounts, emails) is automatically redacted in output. A dedicated test suite (`test_no_data_leak.py`) verifies no personal information leaks through to JSON.

### Integration

- **Home Assistant**: preprocessor for HA sensor data integration
- **Grid data**: [PSE][pse]/[TGE][tge] market data preprocessing for energy cost analysis
- **LLM analysis**: prompt generation from batch invoices for deeper analysis

## Outcome

- Parses real ENEA invoices with full data extraction
- CLI with 6 commands: `parse`, `explain`, `prompt`, `ha-preprocess`, `grid-preprocess`
- Batch processing: single PDF or entire directory
- Human-readable explanation generation from parsed JSON

[enea]: https://en.wikipedia.org/wiki/Enea_(energy_company)
[pdfplumber]: https://github.com/jsvine/pdfplumber
[pydantic]: https://docs.pydantic.dev/
[net-metering]: https://en.wikipedia.org/wiki/Net_metering
[ppe]: https://en.wikipedia.org/wiki/Metering_point
[res]: https://en.wikipedia.org/wiki/Renewable_energy_in_Poland
[pse]: https://en.wikipedia.org/wiki/Polskie_Sieci_Elektroenergetyczne
[tge]: https://en.wikipedia.org/wiki/Towarowa_Gie%C5%82da_Energii
