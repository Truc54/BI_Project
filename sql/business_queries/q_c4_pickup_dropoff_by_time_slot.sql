-- =============================================================================
-- q_c4_pickup_dropoff_by_time_slot.sql
-- Yêu cầu C4: Thống kê số lượng chuyến đón xe và trả khách theo từng thời điểm
--             (khung giờ trong ngày, thứ trong tuần, tháng, năm)
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Year, Month, Day of Week, Daypart, Hour (Đa vai trò Pickup & Drop-off)
-- =============================================================================

WITH pickups AS (
    SELECT
        d.year                                             AS trip_year,
        d.month                                            AS trip_month,
        d.day_of_week                                      AS day_of_week,
        TRIM(d.day_name)                                  AS day_name,
        t.time_of_day_bucket                               AS daypart_bucket,
        t.hour_24                                          AS trip_hour,
        COUNT(f.trip_record_key)                           AS pickup_trip_count
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_date d
        ON f.pickup_date_key = d.date_key
    JOIN dds.dim_time t
        ON f.pickup_time_key = t.time_key
    WHERE f.is_in_study_period = TRUE
    GROUP BY
        d.year,
        d.month,
        d.day_of_week,
        TRIM(d.day_name),
        t.time_of_day_bucket,
        t.hour_24
),

dropoffs AS (
    SELECT
        d.year                                             AS trip_year,
        d.month                                            AS trip_month,
        d.day_of_week                                      AS day_of_week,
        TRIM(d.day_name)                                  AS day_name,
        t.time_of_day_bucket                               AS daypart_bucket,
        t.hour_24                                          AS trip_hour,
        COUNT(f.trip_record_key)                           AS dropoff_trip_count
    FROM dds.fact_yellow_taxi_trip f
    JOIN dds.dim_date d
        ON f.dropoff_date_key = d.date_key
    JOIN dds.dim_time t
        ON f.dropoff_time_key = t.time_key
    WHERE f.is_in_study_period = TRUE
    GROUP BY
        d.year,
        d.month,
        d.day_of_week,
        TRIM(d.day_name),
        t.time_of_day_bucket,
        t.hour_24
)

SELECT
    COALESCE(p.trip_year, dp.trip_year)                    AS trip_year,
    COALESCE(p.trip_month, dp.trip_month)                  AS trip_month,
    COALESCE(p.day_of_week, dp.day_of_week)                AS day_of_week,
    COALESCE(p.day_name, dp.day_name)                      AS day_name,
    COALESCE(p.daypart_bucket, dp.daypart_bucket)          AS daypart_bucket,
    COALESCE(p.trip_hour, dp.trip_hour)                    AS trip_hour,
    COALESCE(p.pickup_trip_count, 0)                       AS pickup_trip_count,
    COALESCE(dp.dropoff_trip_count, 0)                     AS dropoff_trip_count,
    (COALESCE(p.pickup_trip_count, 0) - COALESCE(dp.dropoff_trip_count, 0)) AS net_pickup_surplus
FROM pickups p
FULL OUTER JOIN dropoffs dp
    ON  p.trip_year        = dp.trip_year
    AND p.trip_month       = dp.trip_month
    AND p.day_of_week      = dp.day_of_week
    AND p.trip_hour        = dp.trip_hour
    AND p.daypart_bucket   = dp.daypart_bucket
ORDER BY
    trip_year,
    trip_month,
    day_of_week,
    trip_hour;
