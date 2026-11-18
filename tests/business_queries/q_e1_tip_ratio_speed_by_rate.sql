-- =============================================================================
-- q_e1_tip_ratio_speed_by_rate.sql
-- Yêu cầu E1: So sánh tỷ lệ tiền boa trung bình và vận tốc di chuyển trung bình
--             theo từng loại biểu phí chuyến đi
-- Tác giả: Nguyễn Hồng Phúc (Phase 2 - Business Acceptance Queries)
-- Mức hạt: Rate Code
-- Phương pháp luận:
--   1. Tip Ratio: Chỉ tính trên các giao dịch Credit Card có cước > 0 (QĐ 2 & is_valid_for_tip_ratio).
--      Áp dụng công thức Weighted Macro Tip Ratio = sum(tip_amount) / sum(fare_amount).
--   2. Vận tốc (mph): Chỉ tính trên các cuốc xe đạt chuẩn M9 (is_valid_for_speed).
-- =============================================================================

SELECT
    r.rate_code_key,
    r.rate_description,
    r.rate_category,
    COUNT(f.trip_record_key)                               AS total_trips,
    
    -- Chỉ số Tip Ratio chuẩn hóa
    COUNT(CASE WHEN f.is_valid_for_tip_ratio THEN 1 END)   AS cc_valid_tip_trips,
    ROUND(SUM(CASE WHEN f.is_valid_for_tip_ratio THEN f.tip_amount END), 2)  AS cc_total_tips,
    ROUND(SUM(CASE WHEN f.is_valid_for_tip_ratio THEN f.fare_amount END), 2) AS cc_total_base_fare,
    ROUND(
        100.0 * SUM(CASE WHEN f.is_valid_for_tip_ratio THEN f.tip_amount END)
        / NULLIF(SUM(CASE WHEN f.is_valid_for_tip_ratio THEN f.fare_amount END), 0),
        2
    )                                                      AS weighted_tip_ratio_pct,
    
    -- Chỉ số Vận tốc trung bình chuẩn hóa (mph)
    COUNT(CASE WHEN f.is_valid_for_speed THEN 1 END)       AS speed_eligible_trips,
    ROUND(
        SUM(CASE WHEN f.is_valid_for_speed THEN f.trip_distance END)
        / NULLIF(SUM(CASE WHEN f.is_valid_for_speed THEN (f.duration_minutes / 60.0) END), 0),
        2
    )                                                      AS avg_speed_mph,
    ROUND(
        AVG(CASE WHEN f.is_valid_for_speed THEN f.duration_minutes END),
        2
    )                                                      AS avg_duration_minutes,
    ROUND(
        AVG(CASE WHEN f.is_valid_for_speed THEN f.trip_distance END),
        2
    )                                                      AS avg_distance_miles
FROM dds.fact_yellow_taxi_trip f
JOIN dds.dim_rate_code r
    ON f.rate_code_key = r.rate_code_key
WHERE f.is_in_study_period = TRUE
GROUP BY
    r.rate_code_key,
    r.rate_description,
    r.rate_category
ORDER BY total_trips DESC;
