# Kế hoạch Phân công: Trần Lê Trung Trực

## 1. Trách nhiệm chính
* Phụ trách **tầng Ingestion**: Dựng môi trường hạ tầng (Docker, PostgreSQL 17, Mage AI), thiết kế schema `control` & `stage`, và xây dựng pipeline Mage nạp dữ liệu tăng dần từ Source vào Staging theo cơ chế Watermark.

---

## 2. Đầu vào (Inputs)
* 24 tệp Parquet nguồn Yellow Taxi (2022-01 đến 2023-12) trong thư mục `dataset/trip_data/`.
* Tệp tra cứu vùng `taxi+_zone_lookup.csv` trong `dataset/taxi_zones/`.
* Hai tài liệu hướng dẫn của GV: `01_Hướng dẫn cài đặt và sử dụng Mage.AI.pdf` và `02_Hướng dẫn nạp dữ liệu tăng dần vào stage.pdf`.

---

## 3. Các đầu việc cần làm (Tasks)

### A. Thiết lập Môi trường & Schemas CSDL
1. **Docker Compose & Môi trường:** Tạo `compose.yaml`, `Dockerfile` cho Mage (cài `psycopg2-binary`, `dbt-postgres`, `pyarrow`), và file `.env`.
2. **Khởi tạo Database:** Viết script `postgres/init/01_init.sql` tạo 3 schema: `control`, `stage`, `dds`.
3. **Cấu hình kết nối:** Cấu hình profile kết nối PostgreSQL trong `io_config.yaml` của Mage.

### B. Thiết kế Bảng Control & Staging
1. **Schema `control`:**
   * Tạo bảng `control.etl_watermark` lưu `lset` (thời điểm trích xuất thành công gần nhất) và `cet` (thời điểm trích xuất hiện tại).
   * Tạo bảng `control.etl_batch_log` lưu lịch sử chạy từng batch (tên file, số dòng đọc, số dòng insert, trạng thái `SUCCESS`/`FAILED`, thời gian chạy).
2. **Schema `stage`:**
   * Tạo bảng `stage.raw_yellow_tripdata`: Giữ nguyên 19 cột dữ liệu thô từ nguồn, bổ sung 2 cột lineage/kiểm toán: `source_file_month` (ví dụ: `'2022-01'`) và `source_row_number` (số thứ tự dòng trong file).
   * Tạo bảng `stage.raw_taxi_zones`: Lưu danh mục 265 vùng taxi.

### C. Xây dựng Pipeline Mage Nạp Dữ Liệu Tăng Dần
1. **Xây dựng Mage Pipeline:** Gồm các block theo đúng quy chuẩn Tutorial 02:
   * `get_extraction_window`: Đọc LSET từ `control.etl_watermark`, xác định CET/batch tháng cần nạp.
   * `load_source_files`: Đọc file Parquet theo batch bằng `pyarrow`.
   * `filter_incremental`: Lọc dữ liệu trong cửa sổ trích xuất.
   * `standardize_and_validate`: Chuẩn hóa tên cột snake_case, ép kiểu datetime, thêm 2 cột lineage.
   * `load_stage`: Ghi dữ liệu vào `stage.raw_yellow_tripdata` bằng bulk insert.
   * `commit_watermark`: Cập nhật `LSET = CET` và ghi log `SUCCESS` **chỉ sau khi nạp stage thành công**.
2. **Tự động hóa:** Viết script `run_etl.py` để chạy nạp tự động lần lượt 24 tệp Parquet và nạp bảng lookup zones.

---

## 4. Đầu ra bàn giao (Outputs)
* File `compose.yaml`, `Dockerfile`, `.env.example`.
* Script DDL: `postgres/init/01_init.sql` và DDL tạo bảng Staging/Control.
* Pipeline Mage hoàn chỉnh nạp dữ liệu tăng dần.
* Script điều khiển chạy batch `mage/run_etl.py`.
* Dữ liệu 24 tháng đã nằm đầy đủ trong `stage.raw_yellow_tripdata`, log trạng thái `SUCCESS` trong `control.etl_batch_log`.

---

## 5. Tiêu chí hoàn thành (Done Definition)
* Khởi động toàn bộ cụm dịch vụ qua 1 lệnh: `docker compose up -d`.
* Pipeline nạp trơn tru 24 file Parquet vào Staging, không lỗi, ghi nhận chính xác tổng số dòng trong bảng log.
* Bàn giao bảng Staging sẵn sàng cho Lộc làm tầng clean view.
