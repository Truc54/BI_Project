# Hướng dẫn Vận hành Ingestion: Full Load & Incremental Load

**Tác giả:** Trần Lê Trung Trực (Data Ingestion Lead)  
**Hệ thống:** NYC Yellow Taxi BI Pipeline (Phase 2)  
**Công nghệ:** PostgreSQL 17, Mage AI, Python, Docker Compose  

---

## 1. Cơ chế Hoạt động (Mechanisms)

### A. Full Load (Initial Load / Nạp toàn bộ)
* **Mục đích:** Khởi tạo kho dữ liệu từ đầu hoặc làm mới toàn diện (Full Refresh).
* **Quy trình thực thi:**
  1. `TRUNCATE TABLE stage.raw_yellow_tripdata;` (Làm trống bảng Staging).
  2. Nạp lại toàn bộ 265 Taxi Zones vào `stage.raw_taxi_zones`.
  3. Reset mốc Watermark trong `control.etl_watermark` về `1900-01-01 00:00:00`.
  4. Quét và nạp tuần tự toàn bộ 24 tệp Parquet (`2022-01` đến `2023-12`).
  5. Ghi nhật ký vào `control.etl_batch_log` với `load_type = 'FULL'`.

### B. Incremental Load (Nạp tăng dần)
* **Mục đích:** Định kỳ nạp các batch dữ liệu mới xuất hiện tại nguồn mà không cần nạp lại dữ liệu cũ.
* **Quy trình thực thi (Tuân thủ Tutorial 02):**
  1. Đọc mốc `LSET` (Last Successful Extraction Time) từ bảng `control.etl_watermark`.
  2. Xác định danh sách các tệp nguồn có thời điểm lớn hơn `LSET`: $\text{LSET} < \text{Batch Date} \le \text{CET}$.
  3. Nếu không có batch mới $\rightarrow$ Thông báo hệ thống đã cập nhật mới nhất.
  4. Nếu có batch mới $\rightarrow$ Nạp từng batch vào `stage.raw_yellow_tripdata`, tự động gán lineage (`source_file_month`, `source_row_number`).
  5. Đảm bảo tính bất biến (**Idempotency**): Xóa dữ liệu cũ của batch đó trước khi insert để tránh trùng lặp nếu chạy lại.
  6. **Commit Watermark:** Chỉ cập nhật `LSET = CET` và ghi log `status = 'SUCCESS'`, `load_type = 'INCREMENTAL'` khi và chỉ khi dữ liệu đã ghi xuống Staging thành công.

---

## 2. Các Lệnh Vận hành qua Docker CLI

Tất cả các lệnh được thực thi thông qua container Mage:

```bash
# 1. Xem trạng thái Watermark hiện tại và số lượng dòng trong CSDL:
docker compose exec mage python mage/run_etl.py --status

# 2. Chạy FULL LOAD (Reset toàn bộ và nạp lại từ đầu 24 tháng):
docker compose exec mage python mage/run_etl.py --full-load

# 3. Chạy INCREMENTAL LOAD (Tự động tìm và nạp tất cả các tháng mới hơn LSET):
docker compose exec mage python mage/run_etl.py --incremental-load

# 4. Chạy INCREMENTAL STEP (Chỉ nạp 1 tháng tiếp theo - Dùng để demo cho giảng viên):
docker compose exec mage python mage/run_etl.py --incremental-step

# 5. Nạp một tháng bất kỳ:
docker compose exec mage python mage/run_etl.py --month 2022-03

# 6. Nạp riêng danh mục Taxi Zones:
docker compose exec mage python mage/run_etl.py --load-zones

# 7. Reset sạch Staging và Watermark về ban đầu:
docker compose exec mage python mage/run_etl.py --reset
```

---

## 3. Nhật ký Minh chứng Thực tế (Evidence Log)

### Trạng thái Watermark sau khi chạy Incremental Load:
```text
=== TRẠNG THÁI WATERMARK (control.etl_watermark) ===
Pipeline: yellow_taxi_ingestion | LSET: 2022-03-01 00:00:00 | CET: 2022-03-01 00:00:00 | Status: SUCCESS

=== LỊCH SỬ CÁC BATCH (control.etl_batch_log) ===
Batch #3: Tháng 2022-03 | Kiểu: INCREMENTAL | Đọc: 3,627,882 | Insert: 3,627,882 | Trạng thái: SUCCESS
Batch #2: Tháng 2022-02 | Kiểu: INCREMENTAL | Đọc: 2,979,431 | Insert: 2,979,431 | Trạng thái: SUCCESS
Batch #1: Tháng 2022-01 | Kiểu: INCREMENTAL | Đọc: 2,463,931 | Insert: 2,463,931 | Trạng thái: SUCCESS

=== TIẾN ĐỘ THEO TỪNG THÁNG TRONG STAGING (stage.raw_yellow_tripdata) ===
Tháng 2022-01:  2,463,931 dòng
Tháng 2022-02:  2,979,431 dòng
Tháng 2022-03:  3,627,882 dòng
----------------------------------------
Tổng cộng trong Staging:  9,071,244 dòng (3/24 tháng)
Taxi Zones trong stage: 265 zones
```
