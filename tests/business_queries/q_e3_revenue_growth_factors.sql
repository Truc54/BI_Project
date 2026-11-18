-- =============================================================================
-- q_e3_revenue_growth_factors.sql
-- Yêu cầu E3: Phân rã các yếu tố làm tăng Doanh thu / Chuyến khi sản lượng chuyến ổn định
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Year, Month
-- Phương pháp luận:
--   Phân rã cộng tính Doanh thu/Chuyến thành 5 cấu phần chi tiết:
--   Rev/Trip = Base Fare/Trip + Tips/Trip + Surcharges/Trip + Tolls/Trip + Airport Fee/Trip.
--   Phân tích đối chiếu giữa các giai đoạn để xác định động lực tăng trưởng chính.
-- =============================================================================

SELECT
    d.year                                                 AS trip_year,
    d.month                                                AS trip_month,
    COUNT(f.trip_record_key)                               AS total_trips,
    ROUND(SUM(f.total_amount), 2)                          AS total_revenue,
    
    -- Đơn giá tổng hợp trên mỗi chuyến (Revenue per Trip)
    ROUND(AVG(f.total_amount), 2)                          AS revenue_per_trip,
    
    -- Phân rã 5 cấu phần cước bình quân trên mỗi chuyến
    ROUND(AVG(f.fare_amount), 2)                           AS avg_base_fare,
    ROUND(AVG(f.tip_amount), 2)                            AS avg_tip_amount,
    ROUND(
        AVG(f.extra + f.mta_tax + f.improvement_surcharge + COALESCE(f.congestion_surcharge, 0)), 
        2
    )                                                      AS avg_total_surcharges,
    ROUND(AVG(f.tolls_amount), 2)                          AS avg_tolls,
    ROUND(AVG(COALESCE(f.airport_fee, 0)), 2)              AS avg_airport_fee,
    
    -- Các yếu tố vận hành hành trình giải thích thêm
    ROUND(AVG(f.trip_distance), 2)                         AS avg_distance_miles,
    ROUND(
        AVG(CASE WHEN f.is_valid_duration THEN f.duration_minutes END), 
        2
    )                                                      AS avg_duration_minutes
FROM dds.fact_yellow_taxi_trip f
JOIN dds.dim_date d
    ON f.pickup_date_key = d.date_key
WHERE f.is_in_study_period = TRUE
GROUP BY
    d.year,
    d.month
ORDER BY
    d.year,
    d.month;
