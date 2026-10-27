# Phase 1 Member Plan: Dũng

## Ownership

**Primary workstream:** co-profile the selected data and co-design the logical star schema with Lộc, bringing the source-field, code, and geography evidence into the model.

**Effort target:** approximately 21 hours (planning range 20–22 hours).

**Main outputs:** joint selected-data profile, joint logical star schema, and source evidence for zone/vendor/rate/payment dimensions.

## Work packages

### A. Inventory the selected data (about 2 hours)

- Read the assignment, [Phase 1 overview](phase1_overview.md), TLC Yellow Taxi dictionary, trip user guide, and Parquet guide.
- Inventory the 24 monthly Yellow Taxi Parquet files in `dataset/trip_data`, the zone lookup CSV, and shapefile components.
- Confirm the selected period is January–December 2022 and January–December 2023 using the files and download manifest.
- Record that the selected sample is 2022–2023 and does not cover the full 2009–2026 span described in the assignment.

### B. Co-profile schema and source meaning with Lộc (about 6 hours)

- Inspect Parquet schemas across all 24 files; document field names/types and differences between 2022 and 2023.
- Together with Lộc, identify the source trip grain, available identifiers, timestamp fields, location roles, measures, and fields required for the model.
- Document VendorID, RatecodeID, payment_type, passenger count, trip distance, timestamps, location IDs, and fare components from the selected-year files and applicable TLC dictionaries.
- Preserve raw codes. Verify the project’s CMT/VTS wording against the selected-year dictionary; record unresolved mapping questions rather than guessing.
- Capture source semantics that affect the model: driver-reported passenger count, distance in miles, recorded tips excluding cash tips, and the meaning of `total_amount`.

### C. Co-profile observed values and coverage with Lộc (about 5 hours)

Produce descriptive statistics by month and year, with Lộc reviewing how each result affects the model:

- Row counts, date min/max, monthly coverage, and consistency between file month and trip timestamps.
- Null rates and distinct-value profiles for timestamps, passenger count, distance, provider/rate/payment codes, pickup/drop-off IDs, and monetary fields.
- Counts and distributions of zero, negative, and extreme passenger, duration, distance, fare, and total values.
- Pickup/drop-off timestamp order, duration distribution, and potential speed outliers for positive durations.
- Distinct code values, borough/zone distributions, and location IDs not found in the lookup.
- Candidate duplicate patterns, distinguishing candidates from confirmed duplicate trips when no stable source identifier exists.
- Lookup members with no polygon: IDs 264 and 265.

### D. Co-design source-backed dimensions in the star schema (about 5 hours)

Work with Lộc to design the logical dimensions whose members come from the source and zone reference data:

- `DimTaxiZone`: `LocationID`, zone, borough, service zone, and the relationship to polygons. Retain IDs 264/265 without inventing geometry.
- `DimVendor`: raw vendor code and selected-year description/affiliation; leave CMT/VTS naming unresolved if the dictionary does not settle it.
- `DimRateCode`: raw rate code, dictionary description, and unknown/null treatment.
- `DimPaymentType`: raw payment code and dictionary description; keep no-charge, dispute, voided, unknown, and null meanings distinct where represented.

Agree the dimensions’ business purpose, keys at the logical level, important attributes, hierarchies, and relationships to the trip Fact. Co-author the integrated star-schema diagram with Lộc.

### E. Consolidate and review the shared model (about 3 hours)

- Co-author `selected_data_profile` and the logical star-schema diagram with Lộc; identify which member led each subsection while keeping both as reviewers.
- Review Phúc’s metrics against observed source fields and code meanings.
- Work with Trực to resolve physical-spec questions and ensure the written model preserves source semantics.
- Mark every finding as observed in files, documented by TLC, or unresolved; record open data/model decisions.

## Deliverables

- `source_inventory.md`: selected sources, formats, coverage, and limitations.
- `source_field_dictionary.xlsx` or `.md`: selected-year fields, types, units, and code descriptions.
- `selected_data_profile.xlsx` or `.md` (co-authored with Lộc): monthly/yearly counts, nulls, code domains, value distributions, and observations.
- `reference_dimensions_logical.md` (co-authored with Lộc): logical zone/vendor/rate/payment dimensions and their source-backed members.
- `dds_logical_model.drawio` (co-authored with Lộc): integrated star schema.

## Acceptance checklist

- [ ] All 24 trip files and zone assets are represented in the inventory.
- [ ] Profile findings are based on the selected 2022–2023 files and do not imply full 2009–2026 coverage.
- [ ] The profile distinguishes observed data from dictionary facts and open questions.
- [ ] Zone/vendor/rate/payment dimensions retain raw source keys and documented meanings.
- [ ] CMT/VTS labels are not guessed; IDs 264/265 remain distinct from invalid IDs and have no fabricated polygons.
- [ ] The shared logical star schema reflects observed fields and supports every requirement in Phúc’s matrix.

## Dependencies and handoff

- **From Phúc:** requirement IDs and metric definitions.
- **With Lộc:** joint source profiling and co-authored logical star schema; Dũng leads source evidence, Lộc leads grain and Fact design.
- **From Trực:** physical specification decisions and coverage findings.
- **To the team:** verified source profile, source-backed dimension definitions, and reviewed star-schema diagram.
