-- =============================================================================
-- q_c2_revenue_by_borough_provider_time.sql
-- Yêu cầu C2: Phân tích doanh thu của mỗi quận/khu vực theo từng nhà cung cấp
--             tại các mốc thời điểm (năm, tháng, giờ trong ngày)
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Borough, Vendor, Year, Month, Hour
-- =============================================================================

SELECT
    pz.borough                                             AS pickup_borough,
    v.vendor_short_name                                    AS vendor_provider,
    v.vendor_name                                          AS vendor_full_name,
    d.year                                                 AS trip_year,
    d.month                                                AS trip_month,
    t.hour_24                                              AS trip_hour,
    COUNT(f.trip_record_key)                               AS trip_count,
    ROUND(SUM(f.total_amount), 2)                          AS total_revenue,
    ROUND(SUM(f.fare_amount), 2)                           AS total_base_fare,
    ROUND(AVG(f.total_amount), 2)                          AS avg_revenue_per_trip,
    ROUND(AVG(f.fare_amount), 2)                           AS avg_base_fare_per_trip
FROM dds.fact_yellow_taxi_trip f
JOIN dds.dim_taxi_zone pz
    ON f.pickup_zone_key = pz.zone_key
JOIN dds.dim_vendor v
    ON f.vendor_key = v.vendor_key
JOIN dds.dim_date d
    ON f.pickup_date_key = d.date_key
JOIN dds.dim_time t
    ON f.pickup_time_key = t.time_key
WHERE f.is_in_study_period = TRUE
GROUP BY
    pz.borough,
    v.vendor_short_name,
    v.vendor_name,
    d.year,
    d.month,
    t.hour_24
ORDER BY
    pz.borough,
    d.year,
    d.month,
    t.hour_24,
    v.vendor_short_name;
