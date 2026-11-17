-- =============================================================================
-- q_c7_top_n_routes.sql
-- Yêu cầu C7: Top N tuyến lộ trình phổ biến nhất (Cặp điểm đón -> điểm trả có lượng chuyến cao nhất)
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Ordered O-D Pair (Pickup Zone -> Dropoff Zone)
-- Tham số: Top 10 tuyến phổ biến nhất toàn thành phố
-- =============================================================================

WITH ranked_routes AS (
    SELECT
        f.pickup_zone_key,
        pz.zone_name                                       AS pickup_zone,
        pz.borough                                         AS pickup_borough,
        f.dropoff_zone_key,
        dz.zone_name                                       AS dropoff_zone,
        dz.borough                                         AS dropoff_borough,
        COUNT(f.trip_record_key)                           AS trip_count,
        ROUND(SUM(f.total_amount), 2)                      AS total_revenue,
        ROUND(AVG(f.trip_distance), 2)                     AS avg_distance_miles,
        ROUND(
            AVG(CASE WHEN f.is_valid_duration THEN f.duration_minutes END), 
            2
        )                                                  AS avg_duration_minutes,
        ROUND(AVG(f.fare_amount), 2)                       AS avg_fare_amount,
        DENSE_RANK() OVER (
            ORDER BY COUNT(f.trip_record_key) DESC, SUM(f.total_amount) DESC
        )                                                  AS route_rank
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_taxi_zone pz
        ON f.pickup_zone_key = pz.zone_key
    JOIN dds.dim_taxi_zone dz
        ON f.dropoff_zone_key = dz.zone_key
    WHERE f.is_in_study_period = TRUE
      AND f.pickup_zone_key <> -1
      AND f.dropoff_zone_key <> -1
    GROUP BY
        f.pickup_zone_key,
        pz.zone_name,
        pz.borough,
        f.dropoff_zone_key,
        dz.zone_name,
        dz.borough
)

SELECT
    route_rank,
    pickup_borough,
    pickup_zone,
    dropoff_borough,
    dropoff_zone,
    CONCAT(pickup_zone, ' -> ', dropoff_zone)              AS route_description,
    trip_count,
    total_revenue,
    avg_distance_miles,
    avg_duration_minutes,
    avg_fare_amount
FROM ranked_routes
WHERE route_rank <= 10
ORDER BY route_rank;
