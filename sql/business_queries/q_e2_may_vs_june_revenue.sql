-- =============================================================================
-- q_e2_may_vs_june_revenue.sql
-- Yêu cầu E2: Biến động doanh thu Tháng 5 so với Tháng 6 (năm 2022 và 2023)
--             và phân rã các nhân tố giải thích nguyên nhân biến động
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Year, Month (Tháng 5 vs Tháng 6)
-- Phương pháp luận:
--   Phân rã Doanh thu = Sản lượng (Trip Count) * Đơn giá bình quân (Revenue / Trip).
--   Đối soát số ngày trong tháng (Tháng 5 có 31 ngày vs Tháng 6 có 30 ngày).
--   Phân rã các yếu tố hành trình: Cự ly, Thời lượng, Cước đồng hồ, Tip và Phí sân bay.
-- =============================================================================

WITH monthly_metrics AS (
    SELECT
        d.year                                             AS report_year,
        d.month                                            AS report_month,
        CASE d.month
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'June'
        END                                                AS month_name,
        CASE d.month
            WHEN 5 THEN 31
            WHEN 6 THEN 30
        END                                                AS days_in_month,
        COUNT(f.trip_record_key)                           AS total_trips,
        ROUND(SUM(f.total_amount), 2)                      AS total_revenue,
        ROUND(SUM(f.fare_amount), 2)                       AS total_base_fare,
        ROUND(SUM(f.tip_amount), 2)                        AS total_tips,
        ROUND(SUM(f.airport_fee), 2)                       AS total_airport_fees,
        -- Các chỉ số đơn vị bình quân trên mỗi chuyến
        ROUND(AVG(f.total_amount), 2)                      AS revenue_per_trip,
        ROUND(AVG(f.fare_amount), 2)                       AS fare_per_trip,
        ROUND(AVG(f.trip_distance), 2)                     AS avg_distance_miles,
        ROUND(
            AVG(CASE WHEN f.is_valid_duration THEN f.duration_minutes END), 
            2
        )                                                  AS avg_duration_minutes,
        -- Tỷ lệ cuốc đi sân bay (JFK / Newark: rate_code_key 2, 3)
        ROUND(
            100.0 * COUNT(CASE WHEN f.rate_code_key IN (2, 3) THEN 1 END) 
            / NULLIF(COUNT(f.trip_record_key), 0),
            2
        )                                                  AS airport_trip_share_pct
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_date d
        ON f.pickup_date_key = d.date_key
    WHERE f.is_in_study_period = TRUE
      AND d.month IN (5, 6)
    GROUP BY
        d.year,
        d.month
),

comparison AS (
    SELECT
        report_year,
        report_month,
        month_name,
        days_in_month,
        total_trips,
        ROUND(total_trips::numeric / days_in_month, 0)     AS daily_avg_trips,
        total_revenue,
        ROUND(total_revenue / days_in_month, 2)            AS daily_avg_revenue,
        revenue_per_trip,
        fare_per_trip,
        avg_distance_miles,
        avg_duration_minutes,
        airport_trip_share_pct,
        -- Tính chênh lệch Tháng 6 so với Tháng 5 (June - May)
        total_revenue - LAG(total_revenue) OVER (
            PARTITION BY report_year ORDER BY report_month
        )                                                  AS rev_change_amount,
        ROUND(
            100.0 * (total_revenue - LAG(total_revenue) OVER (
                PARTITION BY report_year ORDER BY report_month
            )) / NULLIF(LAG(total_revenue) OVER (
                PARTITION BY report_year ORDER BY report_month
            ), 0),
            2
        )                                                  AS rev_growth_pct,
        total_trips - LAG(total_trips) OVER (
            PARTITION BY report_year ORDER BY report_month
        )                                                  AS trip_change_count,
        ROUND(
            100.0 * (total_trips - LAG(total_trips) OVER (
                PARTITION BY report_year ORDER BY report_month
            )) / NULLIF(LAG(total_trips) OVER (
                PARTITION BY report_year ORDER BY report_month
            ), 0),
            2
        )                                                  AS trip_growth_pct
    FROM monthly_metrics
)

SELECT * FROM comparison
ORDER BY report_year, report_month;
