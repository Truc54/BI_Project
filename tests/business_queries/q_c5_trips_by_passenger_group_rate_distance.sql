-- =============================================================================
-- q_c5_trips_by_passenger_group_rate_distance.sql
-- Yêu cầu C5: Thống kê số lượng chuyến đi theo nhóm số lượng khách đi,
--             loại biểu phí và dải cự ly di chuyển
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Passenger Group, Rate Code, Distance Range
-- =============================================================================

SELECT
    pg.passenger_group_name                                AS passenger_group,
    r.rate_description                                     AS rate_code_description,
    dr.distance_range_name                                 AS distance_range,
    COUNT(f.trip_record_key)                               AS trip_count,
    SUM(f.passenger_count)                                 AS total_reported_passengers,
    ROUND(AVG(f.trip_distance), 2)                         AS avg_distance_miles,
    ROUND(SUM(f.total_amount), 2)                          AS total_revenue,
    ROUND(AVG(f.total_amount), 2)                          AS avg_revenue_per_trip
FROM dds.fact_yellow_taxi_trip f
JOIN dds.dim_passenger_group pg
    ON f.passenger_group_key = pg.passenger_group_key
JOIN dds.dim_rate_code r
    ON f.rate_code_key = r.rate_code_key
JOIN dds.dim_distance_range dr
    ON f.distance_range_key = dr.distance_range_key
WHERE f.is_in_study_period = TRUE
GROUP BY
    pg.passenger_group_key,
    pg.passenger_group_name,
    r.rate_code_key,
    r.rate_description,
    dr.sort_order,
    dr.distance_range_name
ORDER BY
    pg.passenger_group_key,
    r.rate_code_key,
    dr.sort_order;
