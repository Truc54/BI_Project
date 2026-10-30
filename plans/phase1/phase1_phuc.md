# Phase 1 Member Plan: Phúc

## Ownership

**Primary workstream:** convert the project brief into precise business questions, metric definitions, and required dimensional analysis. Trực separately checks the completed DDS against these requirements.

**Effort target:** approximately 21 hours (planning range 20–22 hours).

**Main outputs:** analytical requirement matrix, metric glossary, required query grain/roll-up definitions, and metric decision log.

## Work packages

### A. Decompose the assignment (about 4 hours)

- Read the assignment and the [Phase 1 overview](phase1_overview.md).
- List every core requirement C1–C8 and extension E1–E5 with a stable ID and short business question.
- For each item, identify the business process, intended analytical result, time scope, geographic attribution, relevant source measures, and dimension roles needed to answer it.
- Clarify ambiguous terms: revenue, passengers, borough/area, average tip ratio, average speed, popular route, and current/prior period.
- Distinguish pickup-zone from drop-off-zone analysis and record which role each requirement needs.

### B. Define metric semantics (about 6 hours)

For every metric, document its formula, unit, denominator, aggregation behavior, treatment of missing values, and source limitations. Include:

- **Trip count:** count qualifying trip records; do not claim unique trips without a stable source key and approved deduplication rule.
- **Reported passengers:** sum valid driver-reported passenger counts separately from trip count; do not interpret it as unique riders.
- **Revenue:** recommend `total_amount` where available, while keeping `fare_amount` and itemized amounts available for analysis. State that the current TLC dictionary says `total_amount` excludes cash tips.
- **Revenue per trip:** sum revenue divided by qualifying trip count in the same context; define zero-trip behavior.
- **Tip ratio:** agree whether the result is mean trip-level `tip_amount / fare_amount` or ratio of total tips to total fares. Use positive fare denominators and disclose that recorded tip data does not include cash tips.
- **Duration and speed:** duration from drop-off minus pickup time; speed from distance miles divided by duration hours. Define how missing, zero, negative, or implausible values are treated in analysis.
- **Passenger group:** one passenger, 2–4, and 5+ based on valid reported values; state treatment of null/zero/out-of-range values.
- **Distance band:** retain raw miles and document chosen band thresholds and rationale; do not invent undocumented cut points.
- **Popular route:** ordered pickup-zone/drop-off-zone pair ranked by trip count; define configurable N and ties.
- **Period comparisons:** define current and comparison period, percent-change denominator, partial-period treatment, and like-for-like month/year alignment.

### C. Translate metrics into dimensional requirements (about 5 hours)

- Map C1–C8 and E1–E5 to the Fact and dimensions co-designed by Dũng and Lộc.
- Specify the required output grain for each question: trip, day, month, year, borough, zone, vendor, payment type, rate code, passenger group, or route pair.
- Specify roll-up paths such as day > month > year, borough > zone, and hour > daypart.
- Identify additive measures, derived measures, ratios, and averages so the DDS model can support correct aggregation.
- Record source-field dependencies and any field-year caveat supplied by Dũng.
- State what the model must contain for each analysis; Trực owns the later check of whether the completed DDS actually contains it.

### D. Resolve analytical decisions with the team (about 4 hours)

- Review provider labels against the selected year-specific dictionary. Keep raw vendor codes and record any unresolved CMT/VTS terminology question.
- Review borough attribution and recommend selectable pickup/drop-off roles.
- Agree whether May/June analysis is for one year, repeated across both years, or both; ensure the year scope is explicit.
- Specify a descriptive revenue decomposition using trip count, revenue per trip, rate/fare mix, distance/duration, charges, provider, and area. Do not claim weather/event causation without supporting data.
- Review the DDS with Lộc and Trực to verify every defined measure and grouping is represented.

### E. Consolidate and review (about 2 hours)

- Publish the requirement matrix and glossary with open decisions, owner, and rationale.
- Walk all requirements with the team and resolve comments in the owned artifacts.
- Confirm the final matrix uses the selected 2022–2023 scope and treats both years as complete calendar years.

## Deliverables

- [`requirements_traceability.md`](requirements_traceability.md): C1–C8 and E1–E5 mapped to required grain, measures, dimensional roles, hierarchies, and analysis period.
- [`metric_glossary.md`](metric_glossary.md): formulas, units, denominators, aggregation, and source caveats.
- [`analysis_grain_matrix.md`](analysis_grain_matrix.md): desired output grain and roll-up/drill-down path per question.
- [`metric_decisions.md`](metric_decisions.md): revenue, tip ratio, passenger grouping, distance bands, borough attribution, comparison periods, and unresolved vendor terminology.

## Acceptance checklist

- [x] Every core and extended requirement has a stable ID and a clear statement of the dimensions/measures required to analyze it.
- [x] Each metric has a formula, unit, denominator, and correct aggregation behavior.
- [x] Pickup and drop-off roles are distinguished where required.
- [x] Revenue, cash-tip, driver-reported passenger, and partial-period limitations are explicit.
- [x] May/June and year-over-year comparisons are reproducible and do not overstate causality.
- [x] The matrix clearly states what the DDS must support for the selected 2022–2023 sample; Trực performs the separate schema coverage check.

## Dependencies and handoff

- **From Dũng and Lộc:** joint selected-year profile and logical star schema.
- **From Trực:** model narrative, physical DDS specification, and question-coverage findings.
- **To the team:** approved metric definitions and model requirement matrix.
