-- =============================================================================
-- q_c1_trips_passengers_by_date.sql
-- Yêu cầu C1: Thống kê số lượng chuyến taxi và số lượng hành khách theo ngày -> tháng -> năm
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt phân tích: Year -> Month -> Day (Hỗ trợ phân cấp Roll-up)
-- =============================================================================

SELECT
    COALESCE(CAST(d.year AS VARCHAR), 'Total All Years')   AS year_level,
    COALESCE(CAST(d.month AS VARCHAR), 'Total All Months') AS month_level,
    COALESCE(CAST(d.full_date AS VARCHAR), 'Total Month')  AS day_level,
    COUNT(f.trip_record_key)                               AS trip_count,
    SUM(f.passenger_count)                                 AS total_reported_passengers,
    ROUND(
        AVG(CASE WHEN f.passenger_count > 0 THEN f.passenger_count END), 
        2
    )                                                      AS avg_passengers_per_trip
FROM dds.fact_yellow_taxi_trip f
JOIN dds.dim_date d 
    ON f.pickup_date_key = d.date_key
WHERE f.is_in_study_period = TRUE
GROUP BY ROLLUP (d.year, d.month, d.full_date)
ORDER BY 
    d.year NULLS LAST, 
    d.month NULLS LAST, 
    d.full_date NULLS LAST;
