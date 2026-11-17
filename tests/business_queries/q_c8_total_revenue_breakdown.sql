-- =============================================================================
-- q_c8_total_revenue_breakdown.sql
-- Yêu cầu C8: Tổng doanh thu và chi tiết phân rã các cấu phần doanh thu
--             (Fare, Extra, MTA Tax, Tip, Tolls, Surcharges, Airport Fee)
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Year, Month kèm dòng tổng kết (ROLLUP)
-- =============================================================================

SELECT
    COALESCE(CAST(d.year AS VARCHAR), 'Total All Years')   AS report_year,
    COALESCE(CAST(d.month AS VARCHAR), 'All Months')       AS report_month,
    COUNT(f.trip_record_key)                               AS total_trips,
    ROUND(SUM(f.total_amount), 2)                          AS total_revenue,
    ROUND(SUM(f.fare_amount), 2)                           AS total_base_fare,
    ROUND(SUM(f.extra), 2)                                 AS total_extra,
    ROUND(SUM(f.mta_tax), 2)                               AS total_mta_tax,
    ROUND(SUM(f.tip_amount), 2)                            AS total_recorded_tips,
    ROUND(SUM(f.tolls_amount), 2)                          AS total_tolls,
    ROUND(SUM(f.improvement_surcharge), 2)                 AS total_improvement_surcharge,
    ROUND(SUM(f.congestion_surcharge), 2)                  AS total_congestion_surcharge,
    ROUND(SUM(f.airport_fee), 2)                           AS total_airport_fee,
    -- Tỷ trọng % đóng góp của từng cấu phần trên Tổng Doanh Thu
    ROUND(100.0 * SUM(f.fare_amount) / NULLIF(SUM(f.total_amount), 0), 2)           AS base_fare_pct,
    ROUND(100.0 * SUM(f.tip_amount) / NULLIF(SUM(f.total_amount), 0), 2)            AS tip_amount_pct,
    ROUND(100.0 * SUM(f.congestion_surcharge) / NULLIF(SUM(f.total_amount), 0), 2)  AS congestion_surcharge_pct,
    ROUND(100.0 * SUM(f.airport_fee) / NULLIF(SUM(f.total_amount), 0), 2)           AS airport_fee_pct,
    ROUND(100.0 * (SUM(f.extra) + SUM(f.mta_tax) + SUM(f.tolls_amount) + SUM(f.improvement_surcharge)) / NULLIF(SUM(f.total_amount), 0), 2) AS other_fees_pct
FROM dds.fact_yellow_taxi_trip f
JOIN dds.dim_date d
    ON f.pickup_date_key = d.date_key
WHERE f.is_in_study_period = TRUE
GROUP BY ROLLUP (d.year, d.month)
ORDER BY
    d.year NULLS LAST,
    d.month NULLS LAST;
