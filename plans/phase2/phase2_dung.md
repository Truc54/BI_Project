# Kế hoạch Phân công: Dương Viết Dũng

## 1. Trách nhiệm chính
* Phụ trách **tầng Kho Dữ Liệu Đa Chiều (`DDS / DW`)**: Xây dựng toàn bộ mô hình Star Schema gồm 8 bảng Dimension và bảng Fact `fact_yellow_taxi_trip` bằng dbt Marts trên PostgreSQL; xử lý nạp tăng dần (incremental load), sinh Surrogate Key và tối ưu hóa Index.

---

## 2. Đầu vào (Inputs)
* Tầng `clean_view` do Lộc bàn giao (`stg_yellow_trips_cleaned` và `stg_taxi_zones_cleaned`).
* Đặc tả mô hình vật lý DDS Phase 1: [dds_physical_spec.md](file:///c:/Users/truct/source/BI_Project/deliverables/phase1/03_dimensional_model/physical/dds_physical_spec.md).
* Báo cáo Phase 1 [report.pdf](file:///c:/Users/truct/source/BI_Project/report.pdf) (Mục 4: Đặc tả DDS).

---

## 3. Các đầu việc cần làm (Tasks)

### A. Xây dựng 8 Bảng Dimension (`dbt/models/marts/`)
Cấu hình `materialized='table'` trong schema `dds`:
1. **`dim_date.sql`:** Tạo chuỗi ngày liên tục từ `2022-01-01` đến `2024-12-31` (gồm `date_key`, `full_date`, `year`, `quarter`, `month`, `month_name`, `day`, `day_of_week`, `day_name`, `is_weekend`).
2. **`dim_time.sql`:** Tạo 1,440 dòng cho từng phút trong ngày ($0 \dots 1439$, kèm `hour_24`, `minute`, `time_of_day_bucket`).
3. **`dim_taxi_zone.sql`:** Nạp từ `stg_taxi_zones_cleaned`, có surrogate key `zone_key`, lưu `location_id`, `borough`, `zone_name`, `service_zone` (gồm cả mã `-1`, `264`, `265`).
4. **`dim_vendor.sql`:** Lưu danh mục nhà cung cấp TPEP (1: CMT, 2: VeriFone, -1: Unknown).
5. **`dim_rate_code.sql`:** Lưu danh mục loại biểu phí (1: Standard, 2: JFK, 3: Newark, 4: Nassau/Westchester, 5: Negotiated, 6: Group ride, 99: Other, -1: Unknown).
6. **`dim_payment_type.sql`:** Lưu danh mục hình thức thanh toán (1: Credit card, 2: Cash, 3: No charge, 4: Dispute, 5: Unknown, 6: Voided trip, -1: Unknown).
7. **`dim_passenger_group.sql`:** Lưu 4 nhóm hành khách (`1 passenger`, `2-4 passengers`, `5+ passengers`, `Unknown/Zero`).
8. **`dim_distance_range.sql`:** Lưu 6 dải cự ly di chuyển (`0-1 mile`, `1-3 miles`, `3-5 miles`, `5-10 miles`, `>10 miles`, `Invalid/Unknown`).

### B. Xây dựng Bảng Fact `fact_yellow_taxi_trip.sql`
1. **Chiến lược Nạp Incremental:**
   * Cấu hình model dạng `materialized='incremental'` với `unique_key='trip_record_key'`.
   * Lọc nạp tăng dần theo `source_file_month` để tối ưu tài nguyên khi xử lý dữ liệu lớn.
2. **Ánh xạ Khóa thay thế (Surrogate Keys):**
   * Sinh `trip_record_key` bằng cách băm kết hợp `source_file_month` và `source_row_number` (dùng macro `dbt_utils.generate_surrogate_key`).
   * Join với 8 Dimension để lấy các khóa ngoại: `pickup_date_key`, `dropoff_date_key`, `pickup_time_key`, `dropoff_time_key`, `pickup_zone_key`, `dropoff_zone_key`, `vendor_key`, `rate_code_key`, `payment_type_key`, `passenger_group_key`, `distance_range_key`.
3. **Lưu trữ Cột Đo lường (Measures) & Lineage:**
   * Lưu các cột kiểm toán: `source_file_month`, `source_row_number`, cờ `is_in_study_period`.
   * Lưu đầy đủ các chỉ số: `passenger_count`, `trip_distance`, `duration_minutes`, `speed_mph`, và 9 cột doanh thu/phụ phí chi tiết.

### C. Tối ưu hóa Index & Hiệu năng Truy vấn
1. Viết script `sql/02_dds_indexes.sql` tạo chỉ mục trên PostgreSQL cho các cột thường xuyên lọc và join:
   * Index trên `pickup_date_key` (kèm điều kiện `WHERE is_in_study_period = TRUE`).
   * Index trên cặp khóa vùng `pickup_zone_key, dropoff_zone_key`.
   * Index trên `vendor_key, payment_type_key`.

---

## 4. Đầu ra bàn giao (Outputs)
* 8 model dbt Dimension trong `dbt/models/marts/dim_*.sql`.
* 1 model dbt Fact: `dbt/models/marts/fact_yellow_taxi_trip.sql`.
* Script tạo index: `sql/02_dds_indexes.sql`.
* Tài liệu schema metadata: `dbt/models/marts/schema.yml`.

---

## 5. Tiêu chí hoàn thành (Done Definition)
* Chạy lệnh `dbt run --select marts` build thành công toàn bộ Star Schema vào schema `dds` trên PostgreSQL.
* Bảng Fact nạp đủ số dòng, $100\%$ khóa ngoại join khớp với các Dimension.
* Bàn giao kho dữ liệu hoàn thiện cho Phúc thực hiện kiểm thử tự động và chạy 13 query nghiệm thu.
