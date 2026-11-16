"""Profile 24 Yellow Taxi Parquet files (2022-01..2023-12) for Phase 1 modeling.

Usage: python profile_selected_data.py [trip_data_dir] [output_json] [zone_lookup_csv]
Requires: duckdb (pip install duckdb)

Populations used in the output (see `_meta.populations`):
  ALL_ROWS   every row of the 24 files, grouped by source file month where stated
  STUDY      rows whose pickup timestamp is in [2022-01-01, 2024-01-01)
  PAYMENT_NZ ALL_ROWS with payment_type <> 0 (excludes the block that lacks metadata)
"""
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

import duckdb

DATA_DIR = Path(sys.argv[1] if len(sys.argv) > 1 else "dataset/trip_data")
OUT = Path(sys.argv[2] if len(sys.argv) > 2 else "profile_results.json")
ZONE_CSV = Path(sys.argv[3] if len(sys.argv) > 3 else "data/reference/taxi_zone_lookup.csv")

STUDY = "tpep_pickup_datetime >= TIMESTAMP '2022-01-01' AND tpep_pickup_datetime < TIMESTAMP '2024-01-01'"
# Sum of the eight component columns; NULL surcharges count as 0 here only
COMPONENTS = ("fare_amount + extra + mta_tax + tip_amount + tolls_amount + improvement_surcharge"
              " + coalesce(congestion_surcharge, 0) + coalesce(airport_fee, 0)")
GAP = f"round(total_amount - ({COMPONENTS}), 2)"
# Amounts are stored as DOUBLE; treat differences up to one cent (plus float noise) as equal
TOL = 0.011

con = duckdb.connect()
# union_by_name merges `airport_fee` (2022-01..2023-01) with `Airport_fee` (2023-02..)
con.execute(f"""
CREATE VIEW trips AS
SELECT regexp_extract(filename, 'yellow_tripdata_(\\d{{4}}-\\d{{2}})\\.parquet', 1) AS file_month, *
FROM read_parquet('{DATA_DIR}/yellow_tripdata_*.parquet', union_by_name=true, filename=true)
""")


def q(sql):
    cur = con.execute(sql)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, [v if isinstance(v, (int, float, str, type(None))) else str(v) for v in row]))
            for row in cur.fetchall()]


results = {}

files = []
for f in sorted(DATA_DIR.glob("yellow_tripdata_*.parquet")):
    files.append({
        "file": f.name,
        "bytes": f.stat().st_size,
        "rows": con.execute(f"SELECT count(*) FROM read_parquet('{f}')").fetchone()[0],
        "schema": [f"{n}:{t}" for n, t in con.execute(
            f"SELECT name, type FROM parquet_schema('{f}') WHERE name <> 'schema'").fetchall()],
    })

results["_meta"] = {
    "generated_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "duckdb_version": duckdb.__version__,
    "python_version": platform.python_version(),
    "data_dir": str(DATA_DIR),
    "zone_lookup": str(ZONE_CSV),
    "file_count": len(files),
    "total_bytes": sum(f["bytes"] for f in files),
    "total_rows": sum(f["rows"] for f in files),
    "files": files,
    "populations": {
        "ALL_ROWS": "every row of the 24 files",
        "STUDY": "rows with tpep_pickup_datetime in [2022-01-01, 2024-01-01)",
        "PAYMENT_NZ": "ALL_ROWS with payment_type <> 0",
    },
    "money_tolerance": TOL,
}

results["columns"] = q("DESCRIBE trips")

# population: ALL_ROWS grouped by source file month
results["monthly"] = q(f"""
SELECT file_month,
  count(*) AS rows,
  min(tpep_pickup_datetime) AS min_pickup, max(tpep_pickup_datetime) AS max_pickup,
  count(*) FILTER (WHERE strftime(tpep_pickup_datetime, '%Y-%m') <> file_month) AS pickup_outside_file_month,
  count(*) FILTER (WHERE NOT ({STUDY})) AS pickup_outside_2022_2023,
  count(*) FILTER (WHERE passenger_count IS NULL) AS null_passenger,
  count(*) FILTER (WHERE RatecodeID IS NULL) AS null_ratecode,
  count(*) FILTER (WHERE store_and_fwd_flag IS NULL) AS null_saf,
  count(*) FILTER (WHERE congestion_surcharge IS NULL) AS null_congestion,
  count(*) FILTER (WHERE airport_fee IS NULL) AS null_airport_fee,
  count(*) FILTER (WHERE VendorID IS NULL) AS null_vendor,
  count(*) FILTER (WHERE payment_type IS NULL) AS null_payment,
  count(*) FILTER (WHERE passenger_count = 0) AS passenger_zero,
  count(*) FILTER (WHERE trip_distance = 0) AS distance_zero,
  count(*) FILTER (WHERE trip_distance < 0) AS distance_negative,
  count(*) FILTER (WHERE fare_amount < 0) AS fare_negative,
  count(*) FILTER (WHERE total_amount < 0) AS total_negative,
  count(*) FILTER (WHERE tpep_dropoff_datetime < tpep_pickup_datetime) AS duration_negative,
  count(*) FILTER (WHERE tpep_dropoff_datetime = tpep_pickup_datetime) AS duration_zero,
  count(*) FILTER (WHERE tpep_dropoff_datetime - tpep_pickup_datetime > INTERVAL 3 HOUR) AS duration_over_3h,
  count(*) FILTER (WHERE tpep_dropoff_datetime - tpep_pickup_datetime > INTERVAL 24 HOUR) AS duration_over_24h
FROM trips GROUP BY file_month ORDER BY file_month
""")

# population: ALL_ROWS and STUDY
results["population_counts"] = q(f"""
SELECT count(*) AS all_rows, count(*) FILTER (WHERE {STUDY}) AS study_rows,
  count(*) FILTER (WHERE NOT ({STUDY})) AS outside_study_rows
FROM trips
""")

# population: ALL_ROWS
results["null_cooccurrence"] = q("""
SELECT count(*) FILTER (WHERE passenger_count IS NULL) AS null_passenger,
  count(*) FILTER (WHERE passenger_count IS NULL AND RatecodeID IS NULL AND store_and_fwd_flag IS NULL
                   AND congestion_surcharge IS NULL AND airport_fee IS NULL) AS all_five_null,
  count(*) FILTER (WHERE payment_type = 0) AS payment_type_0,
  count(*) FILTER (WHERE passenger_count IS NULL AND payment_type = 0) AS null_passenger_and_payment0
FROM trips
""")

# population: ALL_ROWS
results["pickup_year_distribution"] = q("""
SELECT year(tpep_pickup_datetime) AS pickup_year, count(*) AS rows
FROM trips GROUP BY 1 ORDER BY 1
""")

# population: ALL_ROWS; checks the proposed DimDate range 2021-01-01..2024-12-31
results["date_range_vs_dimdate"] = q("""
SELECT
  count(*) FILTER (WHERE tpep_pickup_datetime < TIMESTAMP '2021-01-01'
                      OR tpep_pickup_datetime >= TIMESTAMP '2025-01-01') AS pickup_outside_dimdate,
  count(*) FILTER (WHERE tpep_dropoff_datetime < TIMESTAMP '2021-01-01'
                      OR tpep_dropoff_datetime >= TIMESTAMP '2025-01-01') AS dropoff_outside_dimdate,
  min(tpep_dropoff_datetime) AS min_dropoff, max(tpep_dropoff_datetime) AS max_dropoff
FROM trips
""")

# population: STUDY
for col in ["VendorID", "RatecodeID", "payment_type", "store_and_fwd_flag", "passenger_count",
            "mta_tax", "improvement_surcharge", "congestion_surcharge", "airport_fee"]:
    results[f"domain_{col}"] = q(f"""
    SELECT year(tpep_pickup_datetime) AS pickup_year, {col} AS value, count(*) AS rows
    FROM trips WHERE {STUDY}
    GROUP BY 1, 2 ORDER BY 1, 3 DESC
    """)

# population: STUDY, by pickup month around the fee changes
results["fee_levels_by_pickup_month"] = q(f"""
SELECT strftime(tpep_pickup_datetime, '%Y-%m') AS pickup_month, count(*) AS rows,
  count(*) FILTER (WHERE improvement_surcharge = 0.3) AS improvement_030,
  count(*) FILTER (WHERE improvement_surcharge = 1.0) AS improvement_100,
  count(*) FILTER (WHERE airport_fee = 1.25) AS airport_125,
  count(*) FILTER (WHERE airport_fee = 1.75) AS airport_175
FROM trips WHERE {STUDY} GROUP BY 1 ORDER BY 1
""")

results["fee_first_seen"] = q(f"""
SELECT min(tpep_pickup_datetime) FILTER (WHERE improvement_surcharge = 1.0
           AND tpep_pickup_datetime >= TIMESTAMP '2022-12-01') AS improvement_100_first_pickup_from_2022_12,
  min(tpep_pickup_datetime) FILTER (WHERE airport_fee = 1.75) AS airport_175_first_pickup
FROM trips WHERE {STUDY}
""")

# population: ALL_ROWS
results["location_ids"] = q("""
SELECT 'PU' AS role, count(*) FILTER (WHERE PULocationID = 264) AS id_264, count(*) FILTER (WHERE PULocationID = 265) AS id_265,
  count(*) FILTER (WHERE PULocationID NOT BETWEEN 1 AND 265 OR PULocationID IS NULL) AS invalid_or_null,
  min(PULocationID) AS min_id, max(PULocationID) AS max_id, count(DISTINCT PULocationID) AS distinct_ids
FROM trips
UNION ALL
SELECT 'DO', count(*) FILTER (WHERE DOLocationID = 264), count(*) FILTER (WHERE DOLocationID = 265),
  count(*) FILTER (WHERE DOLocationID NOT BETWEEN 1 AND 265 OR DOLocationID IS NULL),
  min(DOLocationID), max(DOLocationID), count(DISTINCT DOLocationID)
FROM trips
""")

# population: ALL_ROWS
results["passenger_groups"] = q("""
SELECT CASE WHEN passenger_count IS NULL THEN 'NULL' WHEN passenger_count = 0 THEN '0'
            WHEN passenger_count = 1 THEN '1' WHEN passenger_count BETWEEN 2 AND 4 THEN '2-4'
            WHEN passenger_count BETWEEN 5 AND 6 THEN '5-6' ELSE '>6' END AS grp, count(*) AS rows
FROM trips GROUP BY 1 ORDER BY 1
""")

# population: ALL_ROWS; band edges follow Phuc's decision 4 (upper bound inclusive)
results["distance_bands"] = q("""
SELECT CASE WHEN trip_distance IS NULL THEN 'NULL' WHEN trip_distance < 0 THEN '<0'
            WHEN trip_distance <= 1 THEN '0-1' WHEN trip_distance <= 3 THEN '1-3'
            WHEN trip_distance <= 5 THEN '3-5' WHEN trip_distance <= 10 THEN '5-10'
            WHEN trip_distance <= 100 THEN '10-100' ELSE '>100' END AS band, count(*) AS rows,
  max(trip_distance) AS max_distance
FROM trips GROUP BY 1 ORDER BY 1
""")

# population: ALL_ROWS
results["total_reconciliation"] = q(f"""
SELECT count(*) AS rows,
  count(*) FILTER (WHERE abs({GAP}) > {TOL}) AS mismatch_rows,
  sum(total_amount) AS sum_total,
  sum({COMPONENTS}) AS sum_components
FROM trips
""")

# population: ALL_ROWS
results["tip_by_payment"] = q("""
SELECT payment_type, count(*) AS rows, count(*) FILTER (WHERE tip_amount > 0) AS rows_with_tip,
  sum(tip_amount) AS sum_tip, sum(fare_amount) AS sum_fare
FROM trips GROUP BY 1 ORDER BY 1
""")

# population: ALL_ROWS. Exact duplicates: identical across all 19 source columns
results["exact_duplicates"] = q("""
WITH g AS (
  SELECT count(*) AS n FROM trips
  GROUP BY VendorID, tpep_pickup_datetime, tpep_dropoff_datetime, passenger_count, trip_distance, RatecodeID,
           store_and_fwd_flag, PULocationID, DOLocationID, payment_type, fare_amount, extra, mta_tax, tip_amount,
           tolls_amount, improvement_surcharge, total_amount, congestion_surcharge, airport_fee
)
SELECT count(*) FILTER (WHERE n > 1) AS duplicate_groups, coalesce(sum(n - 1) FILTER (WHERE n > 1), 0) AS extra_rows
FROM g
""")

# population: ALL_ROWS. Candidate groups share vendor, both timestamps and both zones.
# A "candidate reversal pair" is a group of exactly one row with total < 0 and one with total > 0;
# "mirrored" additionally requires the negative total to equal minus the positive total.
results["candidate_duplicates"] = q(f"""
WITH g AS (
  SELECT count(*) AS n,
    count(*) FILTER (WHERE total_amount < 0) AS neg, count(*) FILTER (WHERE total_amount > 0) AS pos,
    sum(total_amount) AS net_total
  FROM trips
  GROUP BY VendorID, tpep_pickup_datetime, tpep_dropoff_datetime, PULocationID, DOLocationID
)
SELECT count(*) FILTER (WHERE n > 1) AS candidate_groups,
  coalesce(sum(n) FILTER (WHERE n > 1), 0) AS rows_in_candidate_groups,
  count(*) FILTER (WHERE n = 2 AND neg = 1 AND pos = 1) AS candidate_reversal_pairs,
  count(*) FILTER (WHERE n = 2 AND neg = 1 AND pos = 1 AND abs(net_total) <= {TOL}) AS mirrored_reversal_pairs
FROM g
""")

# population: ALL_ROWS. Negative rows with at least one positive row sharing vendor, timestamps and zones
results["negative_with_original"] = q("""
SELECT count(*) AS negative_rows, count(o.VendorID) AS with_positive_original
FROM (SELECT * FROM trips WHERE total_amount < 0) n
LEFT JOIN (SELECT DISTINCT VendorID, tpep_pickup_datetime, tpep_dropoff_datetime, PULocationID, DOLocationID
           FROM trips WHERE total_amount > 0) o
USING (VendorID, tpep_pickup_datetime, tpep_dropoff_datetime, PULocationID, DOLocationID)
""")

# population: PAYMENT_NZ. Where does total_amount differ from the component sum?
results["total_gap_by_vendor"] = q(f"""
SELECT VendorID, count(*) AS rows, count(*) FILTER (WHERE abs({GAP}) > {TOL}) AS mismatch_rows,
  count(*) FILTER (WHERE abs({GAP}) > {TOL} AND abs({GAP} + congestion_surcharge) <= {TOL}) AS gap_equals_minus_congestion,
  count(*) FILTER (WHERE abs({GAP}) > {TOL} AND abs({GAP} + airport_fee) <= {TOL}) AS gap_equals_minus_airport_fee,
  count(*) FILTER (WHERE abs({GAP}) > {TOL} AND abs({GAP} + congestion_surcharge + airport_fee) <= {TOL}
                   AND airport_fee <> 0 AND congestion_surcharge <> 0) AS gap_equals_minus_both
FROM trips WHERE payment_type <> 0 GROUP BY 1 ORDER BY 1
""")

# population: PAYMENT_NZ
results["total_gap_values"] = q(f"""
SELECT {GAP} AS gap, count(*) AS rows
FROM trips WHERE payment_type <> 0 GROUP BY 1 HAVING abs(gap) > {TOL} ORDER BY 2 DESC LIMIT 10
""")

# population: ALL_ROWS with payment_type = 0
results["payment0_by_vendor"] = q("""
SELECT VendorID, count(*) AS rows, count(*) FILTER (WHERE tip_amount > 0) AS rows_with_tip,
  count(*) FILTER (WHERE abs(fare_amount) > 1000 OR tip_amount > 1000 OR trip_distance > 100) AS extreme_rows,
  median(fare_amount) AS median_fare, median(total_amount) AS median_total
FROM trips WHERE payment_type = 0 GROUP BY 1 ORDER BY 1
""")

# population: ALL_ROWS
results["vendor_5_6_span"] = q("""
SELECT VendorID, min(tpep_pickup_datetime) AS first_pickup, max(tpep_pickup_datetime) AS last_pickup, count(*) AS rows,
  count(*) FILTER (WHERE payment_type = 0) AS payment_type_0_rows
FROM trips WHERE VendorID NOT IN (1, 2) GROUP BY 1 ORDER BY 1
""")

# population: ALL_ROWS
results["borough_share"] = q(f"""
WITH z AS (SELECT * FROM read_csv_auto('{ZONE_CSV}'))
SELECT 'PU' AS role, z.Borough, count(*) AS rows FROM trips JOIN z ON trips.PULocationID = z.LocationID GROUP BY 1, 2
UNION ALL
SELECT 'DO', z.Borough, count(*) FROM trips JOIN z ON trips.DOLocationID = z.LocationID GROUP BY 1, 2
ORDER BY 1, 3 DESC
""")

# population: ALL_ROWS
results["distinct_ordered_routes"] = q("SELECT count(*) AS routes FROM (SELECT DISTINCT PULocationID, DOLocationID FROM trips)")

# population: ALL_ROWS
results["negative_total_by_payment"] = q("""
SELECT payment_type, count(*) AS rows FROM trips WHERE total_amount < 0 GROUP BY 1 ORDER BY 2 DESC
""")

# population: ALL_ROWS. Thresholds from Phuc's M7 (duration) and M9 (speed)
results["duration_speed_filters"] = q("""
WITH t AS (
  SELECT trip_distance, epoch(tpep_dropoff_datetime - tpep_pickup_datetime) AS sec FROM trips
)
SELECT count(*) FILTER (WHERE sec > 0 AND sec <= 86400) AS m7_valid_duration,
  count(*) FILTER (WHERE sec > 0 AND trip_distance > 0) AS positive_dur_and_dist,
  count(*) FILTER (WHERE sec >= 60 AND trip_distance > 0.1) AS m9_base_filter,
  count(*) FILTER (WHERE sec >= 60 AND trip_distance > 0.1 AND trip_distance / (sec / 3600.0) > 80) AS speed_over_80,
  count(*) FILTER (WHERE sec >= 60 AND trip_distance > 0.1 AND trip_distance / (sec / 3600.0) > 100) AS speed_over_100,
  count(*) FILTER (WHERE sec >= 60 AND trip_distance > 0.1 AND trip_distance / (sec / 3600.0) < 1) AS speed_under_1,
  count(*) FILTER (WHERE sec >= 60 AND trip_distance > 0.1
                   AND trip_distance / (sec / 3600.0) BETWEEN 1 AND 80) AS m9_valid_speed,
  count(*) FILTER (WHERE sec > 10800) AS duration_over_180min
FROM t
""")

OUT.write_text(json.dumps(results, indent=1, default=str, ensure_ascii=False))
print(f"wrote {OUT}")
