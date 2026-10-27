# Phase 1 Member Plan: Trực

## Ownership

**Primary workstream:** write the clear description and physical specification of the integrated DDS, then verify that its tables and relationships can answer every required project question.

**Effort target:** approximately 21 hours (planning range 20–22 hours).

**Main outputs:** DDS model narrative, physical data dictionary/schema, and requirement-to-schema coverage matrix.

## Scope boundary

This is modeling documentation and validation only. It does not include pipeline design or implementation, intermediate-layer design, automation, ingestion metadata, ETL test matrices, data loading, or test execution.

## Work packages

### A. Review the modeling inputs (about 3 hours)

- Read the assignment, [Phase 1 overview](phase1_overview.md), Phúc’s metric/requirement matrix, Dũng and Lộc’s joint profile, and their logical star schema.
- Record the agreed fact grain, each dimension’s purpose, dimension roles, hierarchies, and assumptions.
- Note open choices or conflicts before writing the final descriptions; send them to the relevant owner for resolution.

### B. Write the DDS model description (about 4 hours)

- Explain the business process represented by the DDS and the one-row-per-source-trip-record grain.
- Describe the purpose and analytical role of the trip Fact and every dimension.
- Explain how pickup/drop-off date, time, and zone roles work, how route direction is represented, and how borough/zone roll-ups work.
- Describe the date/time, borough/zone, provider, rate, payment, passenger-group, and distance hierarchies/attributes.
- Document assumptions and source limitations in plain language so a reader can understand why each table and relationship exists.

### C. Write the physical DDS specification (about 7 hours)

For every Fact and Dimension, document:

- Table/column names, data types, lengths/precision, units, nullability, definitions, and business meaning.
- Primary keys, foreign keys, dimension business keys, and surrogate-key semantics.
- Types/precision for dates, times, counts, miles, amounts, codes, and derived attributes.
- Separate pickup/drop-off foreign-key roles for date, time, and zone.
- Unknown/null semantics, including the difference between unknown values and valid lookup IDs 264/265 that lack polygons.
- Optional fields in the selected 2022–2023 schemas, distinguishing unavailable from zero.

### D. Validate question coverage against the schema (about 5 hours)

For each core requirement C1–C8 and extension E1–E5:

- Name the Fact measures, dimensions, dimension roles, and hierarchy needed to answer the question.
- Describe the grouping path and any required derivation or denominator, using Phúc’s metric definitions.
- Confirm that the selected 2022–2023 source profile contains the required attributes.
- Flag gaps, ambiguous terms, or assumptions that prevent a reliable answer; send each issue to Phúc, Dũng, or Lộc for resolution.
- Confirm special cases: pickup vs drop-off borough, ordered route pairs, tip ratio, speed, partial-period comparisons, and IDs 264/265 without geometry.

### E. Integrate, review, and publish (about 2 hours)

- Review the descriptions/specification with all members for consistency with the joint logical star schema.
- Resolve comments, version the physical model package, and publish the final coverage matrix and open-decision list.

## Deliverables

- `dds_model_description.md`: fact grain, purpose of tables, relationships, roles, hierarchies, assumptions, and source limitations.
- `dds_physical_spec.xlsx` or `.md`: tables, columns, types, precision, nullability, keys, and definitions.
- `dds_physical_model.drawio`: annotated DDS diagram matching the approved logical star schema.
- `physical_model_coverage.md`: C1–C8/E1–E5 mapped to tables, fields, roles, and calculation needs.
- `dds_model_decisions.md`: resolved and open model questions with rationale and owner.

## Acceptance checklist

- [ ] Model description explains why each Fact/Dimension exists and how their relationships support analysis.
- [ ] Physical DDS fields, types, precision, keys, units, and nullability are explicit.
- [ ] Pickup/drop-off roles and route direction are clearly described.
- [ ] Every required question has a documented schema path or a clearly recorded model gap.
- [ ] Metric coverage matches Phúc’s definitions and Dũng/Lộc’s observed 2022–2023 source profile.
- [ ] IDs 264/265 are modeled without inventing polygon geometry.
- [ ] The final package contains model descriptions/specifications and no pipeline or loading work.

## Dependencies and handoff

- **From Phúc:** approved business definitions, metric formulas, and requirement matrix.
- **From Dũng and Lộc:** joint profile, logical star schema, and source-backed dimension definitions.
- **To the team:** model narrative, physical DDS dictionary/diagram, and completed question-coverage review.
