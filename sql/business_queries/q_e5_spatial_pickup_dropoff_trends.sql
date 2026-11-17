-- =============================================================================
-- q_e5_spatial_pickup_dropoff_trends.sql
-- Yêu cầu E5: Dashboard phân tích vận tải theo không gian và thời gian:
--   a. Lượng chuyến đón/trả trên bản đồ không gian (GIS Choropleth theo Taxi Zone).
--   b. Doanh thu theo quận qua các tháng và xu hướng theo khung giờ trong ngày.
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- =============================================================================

-- =============================================================================
-- PHẦN A: BẢNG DỮ LIỆU KHÔNG GIAN THEO TAXI ZONE (GIS SPATIAL CHOROPLETH)
-- Liên kết trực tiếp qua LocationID (1..263 có shapefile polygon, 264/265 bảng phụ trợ)
-- =============================================================================

WITH zone_pickups AS (
    SELECT
        f.pickup_zone_key                                  AS zone_key,
        COUNT(f.trip_record_key)                           AS pickup_count,
        ROUND(SUM(f.total_amount), 2)                      AS total_pickup_revenue,
        ROUND(AVG(f.fare_amount), 2)                       AS avg_pickup_fare,
        ROUND(AVG(f.trip_distance), 2)                     AS avg_pickup_distance
    FROM dds.fact_yellow_taxi_trip f
    WHERE f.is_in_study_period = TRUE
    GROUP BY f.pickup_zone_key
),

zone_dropoffs AS (
    SELECT
        f.dropoff_zone_key                                 AS zone_key,
        COUNT(f.trip_record_key)                           AS dropoff_count
    FROM dds.fact_yellow_taxi_trip f
    WHERE f.is_in_study_period = TRUE
    GROUP BY f.dropoff_zone_key
)

SELECT
    z.zone_key                                             AS location_id,
    z.borough,
    z.zone_name,
    z.service_zone,
    z.has_geometry,
    COALESCE(p.pickup_count, 0)                            AS total_pickup_trips,
    COALESCE(d.dropoff_count, 0)                           AS total_dropoff_trips,
    (COALESCE(p.pickup_count, 0) - COALESCE(d.dropoff_count, 0)) AS net_mobility_flow,
    COALESCE(p.total_pickup_revenue, 0)                    AS total_revenue,
    COALESCE(p.avg_pickup_fare, 0)                         AS avg_fare_per_trip,
    COALESCE(p.avg_pickup_distance, 0)                     AS avg_distance_miles
FROM dds.dim_taxi_zone z
LEFT JOIN zone_pickups p
    ON z.zone_key = p.zone_key
LEFT JOIN zone_dropoffs d
    ON z.zone_key = d.zone_key
WHERE z.zone_key <> -1
ORDER BY total_pickup_trips DESC;

-- =============================================================================
-- PHẦN B: DOANH THU & LƯU LƯỢNG THEO QUẬN QUA CÁC THÁNG VÀ KHUNG GIỜ (HOURLY HEATMAP)
-- (Sử dụng để xây dựng Heatmap Ma trận Giờ x Tháng cho từng Quận)
-- =============================================================================

/*
SELECT
    pz.borough                                             AS pickup_borough,
    d.year                                                 AS trip_year,
    d.month                                                AS trip_month,
    t.hour_24                                              AS trip_hour,
    t.time_of_day_bucket                                   AS daypart_bucket,
    COUNT(f.trip_record_key)                               AS hourly_trip_intensity,
    ROUND(SUM(f.total_amount), 2)                          AS hourly_revenue,
    ROUND(AVG(f.total_amount), 2)                          AS avg_hourly_fare
FROM dds.fact_yellow_taxi_trip f
JOIN dds.dim_taxi_zone pz
    ON f.pickup_zone_key = pz.zone_key
JOIN dds.dim_date d
    ON f.pickup_date_key = d.date_key
JOIN dds.dim_time t
    ON f.pickup_time_key = t.time_key
WHERE f.is_in_study_period = TRUE
GROUP BY
    pz.borough,
    d.year,
    d.month,
    t.hour_24,
    t.time_of_day_bucket
ORDER BY
    pz.borough,
    d.year,
    d.month,
    t.hour_24;
*/
