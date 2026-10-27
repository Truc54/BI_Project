# Phase 1 Plan: Modeling Only

## Purpose and boundary

Phase 1 is limited to modeling work: interpret analytical requirements, survey and profile selected data so the model reflects real fields and values, and produce an approved conceptual, logical, and physical DDS. The assignment's broader implementation and presentation requirements remain for later phases.

**Phase 1 excludes** pipeline or ETL design/implementation, Source/Staging architecture, ingestion mappings, automation, load metadata, ETL test design or execution, dashboard wireframes, and dashboard/report building. The team will not assign those tasks during this phase.

| Project phase | Scope boundary |
|---|---|
| **Phase 1: Modeling** | Requirements and metric semantics; source survey/profile for modeling; conceptual/logical/physical DDS; model-to-requirement coverage; model decisions. |
| **Phase 2: ETL** | Source > Staging > DDS flow, transformations, automation, metadata, data loading, and ETL tests. |
| **Phase 3: Full project** | Integrate the warehouse with OLAP/report/dashboard work and complete the core and extended analyses and final submission. |

## Project and data facts

- The assignment describes NYC Yellow Taxi trip records for 2009–2026 and requires day/month/year, borough/zone, provider, payment, pickup/drop-off timing, passenger-group, rate, distance, route, revenue, tip, speed, and period-comparison analyses. It also lists broader implementation and presentation deliverables; those are outside this Phase 1 plan.
- The selected local sample is `dataset/trip_data`: 24 official Yellow Taxi Parquet files covering every month of 2022 and 2023, totaling 1,250,843,281 bytes. The manifest contains source URLs, byte counts, SHA-256 values, and download statuses. Analyses and profile findings must be described as 2022–2023 results, not as coverage of 2009–2026.
- The zone lookup CSV has 265 unique `LocationID` rows with `Borough`, `Zone`, and `service_zone`. The shapefile contains 263 polygons for IDs 1–263. IDs 264 (Unknown) and 265 (Outside of NYC) are lookup members without polygons; retain them in the model and do not invent geometry.
- TLC's trip records are supplied by technology providers. Check field availability and code descriptions against the selected years' dictionaries and actual file schemas. Preserve raw codes and document source limitations.

## Modeling requirements to cover

| ID | Analysis in the assignment | Modeling implication |
|---|---|---|
| C1 | Trips and reported passengers by day > month > year | Trip-grain fact, date hierarchy, trip-count and reported-passenger measures. |
| C2 | Revenue by borough/area, provider, and selected date/time | Revenue and charge measures; vendor dimension; pickup/drop-off zone roles; date/time roles. |
| C3 | Payment counts by area and month | Payment-type dimension, zone role, month hierarchy, trip count. |
| C4 | Pickup and drop-off counts by hour, weekday, and month | Separate event roles for pickup/drop-off date, time, and location. |
| C5 | Trips by passenger group, rate type, and distance | Raw passenger count and miles; rate-code dimension; derived passenger groups and documented distance bands. |
| C6 | Borough/area operating analysis | Model must support consistent KPI aggregation by borough and zone; this phase does not design dashboard pages. |
| C7 | Top N popular routes | Ordered pickup-zone/drop-off-zone pair and trip-count measure. |
| C8 | Total revenue | Agreed source measure and itemized components. |
| E1 | Average tip ratio and speed by rate type | Rate-code dimension, duration derivation, tip-rate denominator and averaging rule. |
| E2 | May vs June revenue and possible drivers | Month/year attributes plus trip, revenue/trip, distance, duration, rate/provider/zone mix, and fare-component measures. Trip records alone do not prove external causes. |
| E3 | Revenue rises while trip count is stable | Total revenue, trip count, revenue per trip, and component/mix measures. |
| E4 | Current vs previous month/year | Date hierarchy and like-for-like comparison periods; identify partial periods. |
| E5 | Spatial pickup/drop-off and borough-month/hour trends | Zone lookup attributes and geometry relationship; pickup/drop-off roles; month/hour attributes. |

## Proposed model baseline

Use **one row per Yellow Taxi trip record** as the proposed fact grain. Do not assume the source has a stable trip identifier until Dũng profiles the selected files. The logical DDS should support:

- A trip fact with pickup/drop-off date, time, and zone roles; vendor, rate-code, and payment-type roles; raw passenger count, trip distance, and available monetary components.
- Date and time dimensions that support date > month > year, weekday, hour, and daypart analysis.
- A taxi-zone dimension sourced from the lookup and usable in both pickup and drop-off roles. Keep lookup IDs 264/265 even though they have no polygons.
- Provider, rate-code, and payment-type dimensions with raw codes retained and descriptions documented for the selected years.
- Derived passenger groups, distance bands, duration, speed, and revenue-per-trip definitions that retain their source inputs and clearly state calculation rules.

## Balanced member allocation

Each member targets approximately **20–22 hours**. Work is split into complementary packages so each person owns a distinct artifact and reviews the integrated DDS.

| Member | Phase 1 ownership | Detailed plan |
|---|---|---|
| **Phúc** | Business questions, metric definitions, and required analytical grain/dimensions | [phase1_phuc.md](phase1_phuc.md) |
| **Dũng** | Co-owner of data profiling and logical star schema; leads source evidence and code/geography dimensions | [phase1_dung.md](phase1_dung.md) |
| **Lộc** | Co-owner of data profiling and logical star schema; leads trip grain, Fact, roles, and relationships | [phase1_loc.md](phase1_loc.md) |
| **Trực** | Model narrative, physical DDS specification, and requirement-to-schema validation | [phase1_truc.md](phase1_truc.md) |

## Phase 1 deliverables

1. Phúc analytical requirement/metric matrix for C1–C8 and E1–E5, plus Trực validation of those questions against the finished DDS.
2. Metric glossary with formula, units, aggregation, denominator, and source caveats.
3. Joint source inventory/profile by Dũng and Lộc, including observed anomalies and selected-year field/code dictionary.
4. Conceptual and logical star-schema diagrams co-authored by Dũng and Lộc, with fact grain, dimensions, roles, keys, and hierarchies.
5. Model description and physical DDS specification by Trực, with tables, attributes, types, keys, null/unknown member semantics, and decisions.
6. Requirement-to-schema coverage matrix by Trực and a shared consolidated decision log.

## Phase 1 acceptance criteria

- Every core and extended analysis maps to a fact, measures, dimension roles, and hierarchy in the DDS.
- The grain is explicit; pickup and drop-off are modeled as separate date/time/location roles.
- Metric definitions have units and aggregation rules. Averages and ratios are not summed or averaged again without a stated denominator.
- Source findings come from the selected 2022–2023 files or are clearly labeled as TLC documentation/unknown; no conclusions are generalized to 2009–2026.
- The zone lookup/shapefile mismatch and vendor-code naming questions are visible in the model decisions.
- The physical DDS is reviewable independently of pipeline, staging, or presentation artifacts.




