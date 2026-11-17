-- =============================================================================
-- q_c6_borough_operating_analysis.sql
-- Yêu cầu C6: Dashboard phân tích tình hình hoạt động vận tải taxi của từng quận/khu vực
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Borough (Tổng hợp KPI vận hành không gian đa chiều)
-- =============================================================================

WITH pickup_kpi AS (
    SELECT
        pz.borough                                         AS borough,
        COUNT(f.trip_record_key)                           AS pickup_trips,
        ROUND(SUM(f.total_amount), 2)                      AS total_revenue,
        ROUND(AVG(f.fare_amount), 2)                       AS avg_fare,
        ROUND(AVG(f.trip_distance), 2)                     AS avg_distance,
        ROUND(
            AVG(CASE WHEN f.is_valid_duration THEN f.duration_minutes END), 
            2
        )                                                  AS avg_duration_minutes
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_taxi_zone pz
        ON f.pickup_zone_key = pz.zone_key
    WHERE f.is_in_study_period = TRUE
    GROUP BY pz.borough
),

dropoff_kpi AS (
    SELECT
        dz.borough                                         AS borough,
        COUNT(f.trip_record_key)                           AS dropoff_trips
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_taxi_zone dz
        ON f.dropoff_zone_key = dz.zone_key
    WHERE f.is_in_study_period = TRUE
    GROUP BY dz.borough
)

SELECT
    COALESCE(p.borough, d.borough)                         AS borough,
    COALESCE(p.pickup_trips, 0)                            AS pickup_trips,
    COALESCE(d.dropoff_trips, 0)                           AS dropoff_trips,
    (COALESCE(p.pickup_trips, 0) - COALESCE(d.dropoff_trips, 0)) AS net_flow_mobility,
    ROUND(
        CAST(COALESCE(p.pickup_trips, 0) AS NUMERIC) / NULLIF(d.dropoff_trips, 0), 
        3
    )                                                      AS pickup_to_dropoff_ratio,
    COALESCE(p.total_revenue, 0)                           AS total_revenue,
    COALESCE(p.avg_fare, 0)                                AS avg_fare_per_trip,
    COALESCE(p.avg_distance, 0)                            AS avg_distance_miles,
    COALESCE(p.avg_duration_minutes, 0)                    AS avg_duration_minutes
FROM pickup_kpi p
FULL OUTER JOIN dropoff_kpi d
    ON p.borough = d.borough
ORDER BY pickup_trips DESC;
