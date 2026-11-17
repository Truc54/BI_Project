-- =============================================================================
-- q_e4_period_comparison_yoy_mom.sql
-- Yêu cầu E4: So sánh doanh thu và số lượng chuyến đi cùng kỳ
--             (Tháng hiện tại vs Tháng trước MoM / Năm hiện tại vs Năm trước YoY)
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Year, Month (24 tháng trọn vẹn 2022 - 2023)
-- =============================================================================

WITH monthly_series AS (
    SELECT
        d.year                                             AS trip_year,
        d.month                                            AS trip_month,
        TO_CHAR(d.full_date, 'YYYY-MM')                   AS year_month,
        COUNT(f.trip_record_key)                           AS trip_count,
        ROUND(SUM(f.total_amount), 2)                      AS total_revenue,
        ROUND(AVG(f.total_amount), 2)                      AS revenue_per_trip
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_date d
        ON f.pickup_date_key = d.date_key
    WHERE f.is_in_study_period = TRUE
    GROUP BY
        d.year,
        d.month,
        TO_CHAR(d.full_date, 'YYYY-MM')
)

SELECT
    trip_year,
    trip_month,
    year_month,
    trip_count,
    total_revenue,
    revenue_per_trip,
    
    -- Tăng trưởng so với tháng liền kề (Month-over-Month - MoM)
    LAG(total_revenue, 1) OVER (ORDER BY trip_year, trip_month)  AS prior_month_revenue,
    ROUND(
        100.0 * (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY trip_year, trip_month))
        / NULLIF(LAG(total_revenue, 1) OVER (ORDER BY trip_year, trip_month), 0),
        2
    )                                                            AS revenue_mom_growth_pct,
    LAG(trip_count, 1) OVER (ORDER BY trip_year, trip_month)     AS prior_month_trips,
    ROUND(
        100.0 * (trip_count - LAG(trip_count, 1) OVER (ORDER BY trip_year, trip_month))
        / NULLIF(LAG(trip_count, 1) OVER (ORDER BY trip_year, trip_month), 0),
        2
    )                                                            AS trips_mom_growth_pct,
    
    -- Tăng trưởng so với cùng kỳ năm trước (Year-over-Year - YoY)
    LAG(total_revenue, 12) OVER (ORDER BY trip_year, trip_month) AS prior_year_revenue,
    ROUND(
        100.0 * (total_revenue - LAG(total_revenue, 12) OVER (ORDER BY trip_year, trip_month))
        / NULLIF(LAG(total_revenue, 12) OVER (ORDER BY trip_year, trip_month), 0),
        2
    )                                                            AS revenue_yoy_growth_pct,
    LAG(trip_count, 12) OVER (ORDER BY trip_year, trip_month)    AS prior_year_trips,
    ROUND(
        100.0 * (trip_count - LAG(trip_count, 12) OVER (ORDER BY trip_year, trip_month))
        / NULLIF(LAG(trip_count, 12) OVER (ORDER BY trip_year, trip_month), 0),
        2
    )                                                            AS trips_yoy_growth_pct
FROM monthly_series
ORDER BY trip_year, trip_month;
