-- =============================================================================
-- q_c3_payment_counts_by_area_month.sql
-- Yêu cầu C3: Thống kê số lượng chuyến đi thanh toán theo từng hình thức
--             ở từng quận/khu vực theo từng tháng trong năm
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Borough, Payment Type, Year, Month
-- =============================================================================

WITH payment_summary AS (
    SELECT
        pz.borough                                         AS pickup_borough,
        d.year                                             AS trip_year,
        d.month                                            AS trip_month,
        p.payment_type_key,
        p.payment_description                              AS payment_method,
        COUNT(f.trip_record_key)                           AS trip_count,
        ROUND(SUM(f.total_amount), 2)                      AS total_revenue
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_taxi_zone pz
        ON f.pickup_zone_key = pz.zone_key
    JOIN dds.dim_payment_type p
        ON f.payment_type_key = p.payment_type_key
    JOIN dds.dim_date d
        ON f.pickup_date_key = d.date_key
    WHERE f.is_in_study_period = TRUE
    GROUP BY
        pz.borough,
        d.year,
        d.month,
        p.payment_type_key,
        p.payment_description
)

SELECT
    pickup_borough,
    trip_year,
    trip_month,
    payment_method,
    trip_count,
    ROUND(
        100.0 * trip_count / SUM(trip_count) OVER (
            PARTITION BY pickup_borough, trip_year, trip_month
        ),
        2
    )                                                      AS payment_trip_share_pct,
    total_revenue
FROM payment_summary
ORDER BY
    pickup_borough,
    trip_year,
    trip_month,
    trip_count DESC;
