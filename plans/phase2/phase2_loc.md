# Kế hoạch Phân công: Lê Văn Lộc

## 1. Trách nhiệm chính
* Phụ trách **tầng Làm sạch & Biến đổi trung gian (`clean_view`)**: Xây dựng các model dbt Staging để chuẩn hóa dữ liệu thô từ bảng Staging của Trực, xử lý dị thường, tính toán các trường dẫn xuất và gán cờ nghiệp vụ phục vụ nạp vào Data Warehouse.

---

## 2. Đầu vào (Inputs)
* Dữ liệu thô trong `stage.raw_yellow_tripdata` và `stage.raw_taxi_zones` do Trực bàn giao.
* Kết quả khảo sát dị thường Phase 1: [selected_data_profile_observed.md](file:///c:/Users/truct/source/BI_Project/deliverables/phase1/01_data_understanding/selected_data_profile_observed.md).
* Quy tắc tính chỉ số Phase 1: [metric_decisions.md](file:///c:/Users/truct/source/BI_Project/deliverables/phase1/02_requirements_and_metrics/metric_decisions.md).

---

## 3. Các đầu việc cần làm (Tasks)

### A. Khởi tạo dbt Staging Models
1. Khai báo nguồn dữ liệu `stage` trong `dbt/models/staging/sources.yml`.
2. Tạo 2 model view:
   * `stg_taxi_zones_cleaned.sql`: Làm sạch dữ liệu taxi zones.
   * `stg_yellow_trips_cleaned.sql`: Làm sạch và chuẩn hóa dữ liệu cuốc xe.

### B. Xây dựng Logic Làm sạch trong `stg_yellow_trips_cleaned`
1. **Chuẩn hóa Khóa Ngày & Giờ:**
   * Tách pickup/dropoff datetime thành khóa ngày dạng số nguyên `YYYYMMDD` (`pickup_date_key`, `dropoff_date_key`).
   * Tách pickup/dropoff datetime thành khóa thời gian theo số phút trong ngày $0 \dots 1439$ (`pickup_time_key`, `dropoff_time_key`).
2. **Cờ phạm vi nghiên cứu (`is_in_study_period`):**
   * Gán `TRUE` cho các chuyến có thời điểm đón trong giai đoạn `2022-01-01` đến trước `2024-01-01`, ngược lại gán `FALSE`.
3. **Thời lượng chuyến & Vận tốc:**
   * Tính `duration_minutes` (hiệu giữa dropoff và pickup theo phút).
   * Tính vận tốc trung bình `speed_mph` = $\text{distance} / \text{hours}$ (gán `NULL` nếu duration $\le 0$ hoặc vận tốc $> 120$ mph).
4. **Phân nhóm khách & Dải cự ly:**
   * Phân nhóm hành khách (`passenger_group_name`): `1 passenger`, `2-4 passengers`, `5+ passengers`, `Unknown/Zero`.
   * Phân dải cự ly (`distance_range_name`): `0-1 mile`, `1-3 miles`, `3-5 miles`, `5-10 miles`, `>10 miles`, `Invalid/Unknown`.
5. **Xử lý Mã không xác định (Unknown Handling):**
   * Map các giá trị NULL hoặc mã lạ của `vendor_id`, `rate_code_id`, `payment_type`, `PULocationID`, `DOLocationID` về mã chuẩn `-1` (Unknown).
6. **Xử lý Cước phí:**
   * Giữ nguyên các trường cước phí chi tiết (`fare_amount`, `tip_amount`, `total_amount`,...).
   * Gán cờ `is_negative_charge` cho các cuốc có tiền âm để phục vụ phân tích cuốc hoàn tiền/tranh chấp.

### C. Xây dựng Model `stg_taxi_zones_cleaned`
1. Chuẩn hóa tên các quận chính (`Manhattan`, `Queens`, `Brooklyn`, `Bronx`, `Staten Island`, `EWR`).
2. Bổ sung bản ghi mặc định cho trường hợp không xác định: `location_id = -1` (`Unknown Zone`).
3. Giữ nguyên 2 mã hợp lệ không có hình học là `264` (Unknown) và `265` (Outside of NYC).

---

## 4. Đầu ra bàn giao (Outputs)
* Hai model dbt staging view: `stg_yellow_trips_cleaned.sql` và `stg_taxi_zones_cleaned.sql`.
* File cấu hình dbt: `sources.yml` và `schema.yml`.
* Tài liệu tóm tắt quy tắc làm sạch: `docs/cleaning_rules.md`.

---

## 5. Tiêu chí hoàn thành (Done Definition)
* Chạy lệnh `dbt run --select staging` tạo thành công 2 view trên PostgreSQL.
* View cung cấp đầy đủ các khóa đã chuẩn hóa, không còn giá trị NULL hay mã lạ nào bị mồ côi (tất cả đã được fallback về `-1`).
* Bàn giao tầng `clean_view` sẵn sàng cho Dũng ánh xạ vào kho DDS.
