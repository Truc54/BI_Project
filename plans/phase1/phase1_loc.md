# Phase 1 Member Plan: Lộc

## Ownership

**Primary workstream:** co-profile the selected data and co-design the logical star schema with Dũng, leading the fact grain, trip Fact, and dimensional relationships.

**Effort target:** approximately 21 hours (planning range 20–22 hours).

**Main outputs:** joint selected-data profile, trip-fact design, and co-authored logical star-schema diagram.

## Work packages

### A. Co-profile data for modeling and confirm the grain (about 4 hours)

- Read the assignment, [Phase 1 overview](phase1_overview.md), Phúc’s metrics/requirements, and Dũng’s source inventory.
- Inspect the selected 2022–2023 files with Dũng to understand fields, identifiers, timestamps, codes, measures, and monthly coverage.
- Propose **one row per Yellow Taxi trip record** as the Fact grain. Do not call it a guaranteed unique trip unless the selected files provide a supported identifier.
- Review observed duplicate candidates, timestamp/date ranges, and null patterns for implications to grain and fact attributes.

### B. Lead the logical trip Fact design (about 6 hours)

Design `FactYellowTaxiTrip` at one record per source trip, including:

- Pickup and drop-off date, time, and zone roles as separate logical relationships.
- Vendor, rate-code, and payment-type dimension relationships using Dũng’s source-backed designs.
- Raw reported passenger count, trip distance in miles, timestamps or equivalent date/time roles, and monetary fields present in the selected files.
- Fare, extras, taxes, tip, tolls, surcharges, airport fee, and `total_amount` where available in 2022–2023.
- Raw inputs for Phúc’s trip count, passenger totals, revenue, revenue/trip, tip ratio, duration, and speed definitions.
- An explicit note that the grain is a source record, not automatically a unique trip.

### C. Co-design zone and code dimensions with Dũng (about 5 hours)

- Co-author the logical `DimTaxiZone`, `DimVendor`, `DimRateCode`, and `DimPaymentType` designs with Dũng, ensuring they join correctly to the trip Fact.
- Define pickup and drop-off as two roles referencing the same taxi-zone dimension.
- Retain lookup IDs 264/265 as valid source members without polygons; keep them distinct from invalid IDs.
- Keep route direction: A-to-B is different from B-to-A. Define popular-route grain as ordered pickup-zone/drop-off-zone pair.
- Confirm borough analysis can select pickup or drop-off attribution.

### D. Define logical Date/Time and analysis groupings with Dũng (about 3 hours)

- Co-design `DimDate` and `DimTime` with Dũng so the schema supports day > month > year, weekday, hour, and daypart questions.
- Connect pickup and drop-off events to the appropriate date/time roles.
- Represent passenger groups and distance bands without replacing the raw passenger count or miles.
- Ensure duration, speed, and revenue-per-trip can be derived from retained Fact inputs and Phúc’s formulas.

### E. Integrate and review the logical model (about 3 hours)

- Co-author the complete star-schema diagram and selected-data profile with Dũng.
- Map C1–C8 and E1–E5 to exact Fact measures, dimensions, roles, and roll-up paths.
- Review with Phúc and Trực; revise the logical model to reflect metrics, actual source fields, and physical-spec findings.
- Record decisions for grain, roles, route direction, unknown members, and derived groupings.

## Deliverables

- `fact_grain_and_process.md`: trip process, grain, and identity caveat.
- `fact_yellow_taxi_trip_logical.md`: Fact attributes, measures, and dimension roles.
- `dds_logical_model.drawio` (co-authored with Dũng): integrated star schema.
- `selected_data_profile.xlsx` or `.md` (co-authored with Dũng): profile findings and modeling implications.
- `logical_model_requirement_mapping.md`: expected logical Fact/dimension path for each requirement, for Trực to validate against the final physical specification.

## Acceptance checklist

- [ ] Fact grain is one source trip record and is not mislabeled as a unique-trip grain.
- [ ] Fact measures retain the raw inputs needed by Phúc’s metric formulas.
- [ ] Pickup/drop-off date, time, and location are distinct roles.
- [ ] Zone/code/date/time dimensions are co-designed with Dũng and represented in the integrated schema.
- [ ] Route ranking uses an ordered pickup/drop-off pair.
- [ ] Passenger and distance groups preserve raw values.
- [ ] The logical model is based on the selected profile and covers every project requirement.

## Dependencies and handoff

- **From Phúc:** metric formulas, output grains, comparison rules, and requirement matrix.
- **With Dũng:** joint source profiling and co-authored star schema; Lộc leads grain and Fact design, Dũng leads source-field/code/geography evidence.
- **From Trực:** physical specification feedback and requirement-coverage findings.
- **To Trực:** integrated logical star schema for narrative description, physical specification, and question coverage review.

