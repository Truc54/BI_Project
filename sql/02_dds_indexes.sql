-- =============================================================================
-- 02_dds_indexes.sql: Tối ưu hóa Chỉ mục (Indexes) trên Schema DDS (PostgreSQL)
-- Tác giả: Dương Viết Dũng (Phase 2 - Data Warehouse Marts)
-- Mục đích: Tăng tốc độ truy vấn phân tích cho 13 câu hỏi C1-C8 & E1-E5 của Phúc
-- =============================================================================

-- 1. Index trên khóa ngày đón (phổ biến nhất qua hầu hết các câu hỏi C1, C2, C3, C8, E2, E3, E4)
-- Kèm điều kiện lọc theo kỳ nghiên cứu 2022-2023 (Partial Index)
CREATE INDEX IF NOT EXISTS idx_fact_pickup_date_study
ON dds.fact_yellow_taxi_trip (pickup_date_key)
WHERE is_in_study_period = TRUE;

-- 2. Index trên khóa ngày trả khách (phục vụ đối soát đón/trả và câu hỏi C4, C6)
CREATE INDEX IF NOT EXISTS idx_fact_dropoff_date
ON dds.fact_yellow_taxi_trip (dropoff_date_key);

-- 3. Composite Index trên cặp đón/trả Taxi Zone (phục vụ câu hỏi Top N tuyến C7 và Net Flow C6)
CREATE INDEX IF NOT EXISTS idx_fact_route_zones
ON dds.fact_yellow_taxi_trip (pickup_zone_key, dropoff_zone_key);

-- 4. Index trên vùng đón riêng biệt (phục vụ phân tích địa lý C2, C3, E5)
CREATE INDEX IF NOT EXISTS idx_fact_pickup_zone
ON dds.fact_yellow_taxi_trip (pickup_zone_key);

-- 5. Index trên nhà cung cấp và hình thức thanh toán (phục vụ câu hỏi C2, C3, E2)
CREATE INDEX IF NOT EXISTS idx_fact_vendor_payment
ON dds.fact_yellow_taxi_trip (vendor_key, payment_type_key);

-- 6. Index trên biểu cước Rate Code (phục vụ so sánh tip ratio và tốc độ E1, C5)
CREATE INDEX IF NOT EXISTS idx_fact_rate_code
ON dds.fact_yellow_taxi_trip (rate_code_key);

-- 7. Composite Index trên nhóm khách và dải cự ly (phục vụ câu hỏi phân khúc C5)
CREATE INDEX IF NOT EXISTS idx_fact_passenger_distance
ON dds.fact_yellow_taxi_trip (passenger_group_key, distance_range_key);

-- 8. Index trên thời gian phút trong ngày (phục vụ phân tích khung giờ đón C4, E5b)
CREATE INDEX IF NOT EXISTS idx_fact_pickup_time
ON dds.fact_yellow_taxi_trip (pickup_time_key);
