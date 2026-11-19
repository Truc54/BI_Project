Hệ thống **Data Warehouse & ETL Pipeline** cho bộ dữ liệu **NYC TLC Yellow Taxi Trip Records (2022–2023)**, triển khai theo kiến trúc đa tầng **`Source → Staging → Clean View → DDS`** sử dụng **PostgreSQL 17**, **Mage AI**, **dbt Core** và **Docker Compose**.


## 1. Nguồn dữ liệu 

Dự án sử dụng dữ liệu chính thức từ **NYC Taxi & Limousine Commission (TLC)** trong giai đoạn **01/2022 – 12/2023** (24 tệp tháng):

- **Trang tải chính thức:** [TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- **Các tệp cần tải:**
  - 24 tệp **Yellow Taxi Trip Records** dạng Parquet từ `yellow_tripdata_2022-01.parquet` đến `yellow_tripdata_2023-12.parquet` *(không thay thế bằng Green Taxi hay FHV)*.
  - Tệp danh mục vùng **Taxi Zone Lookup** (`taxi+_zone_lookup.csv`, 265 zones) và **Taxi Zones Shapefile** *(bản sao tham chiếu nhẹ đã có sẵn trong `data/reference/`)*.

Đặt dữ liệu tải về vào thư mục `dataset/` tại gốc dự án:

```text
dataset/
├── taxi+_zone_lookup.csv
├── taxi_zones/
│   └── ...
└── trip_data/
    ├── yellow_tripdata_2022-01.parquet
    ├── yellow_tripdata_2022-02.parquet
    ├── ...
    └── yellow_tripdata_2023-12.parquet
```

---

## 2. Kiến trúc Kho dữ liệu & Luồng ETL

```text
24 tệp Parquet + Taxi Zones CSV (dataset/)
        │
        ▼  [Mage AI / mage/run_etl.py — Full & Incremental Watermark]
PostgreSQL: schema [control]  (etl_watermark, etl_batch_log)
            schema [stage]    (raw_yellow_tripdata, raw_taxi_zones)
        │
        ▼  [dbt Staging — models/staging/]
PostgreSQL: schema [clean_view]
            (stg_yellow_trips_cleaned, stg_taxi_zones_cleaned)
        │
        ▼  [dbt Marts — models/marts/ + sql/02_dds_indexes.sql]
PostgreSQL: schema [dds] — Star Schema
            ├── 8 Dimensions: dim_date, dim_time, dim_taxi_zone, dim_vendor,
            │                 dim_rate_code, dim_payment_type,
            │                 dim_passenger_group, dim_distance_range
            └── 1 Fact (Incremental): fact_yellow_taxi_trip
        │
        ▼  [dbt Tests + 13 Business Queries]
Kiểm thử toàn vẹn (PK/FK, Row Count, Revenue Balance) & Nghiệm thu C1–C8, E1–E5
```

### Công nghệ & Schema cơ sở dữ liệu

| Thành phần | Công nghệ / Schema | Chức năng |
| :--- | :--- | :--- |
| **Điều phối ETL** | Mage AI (`mageai/mageai:latest`) | Pipeline `yellow_taxi_ingestion` gồm 7 block tự động hóa từ đọc nguồn đến chạy `dbt` |
| **Chuyển đổi & Kiểm thử** | dbt Core (`dbt-postgres`) | Xây dựng view `clean_view`, Star Schema `dds` (incremental `delete+insert`) và chạy test |
| **Cơ sở dữ liệu** | PostgreSQL 17 | Lưu trữ 4 schema: `control`, `stage`, `clean_view`, `dds` |
| **Quản trị & Hạ tầng** | pgAdmin 4, Docker Compose | Đóng gói và khởi chạy đồng bộ toàn bộ môi trường |

---

## 3. Cấu trúc thư mục dự án

```text
BI_Project/
├── compose.yaml                  # Cấu hình Docker Compose (postgres, mage, pgadmin)
├── Dockerfile                    # Image Mage AI cài sẵn dbt-postgres, psycopg2-binary, pyarrow
├── .env.example                  # Mẫu biến môi trường kết nối PostgreSQL
├── README.md                     # Tài liệu hướng dẫn tổng quan & vận hành
├── postgres/
│   └── init/
│       └── 01_init.sql           # DDL khởi tạo 4 schema và các bảng control/stage
├── lab_project/                  # Mage AI project
│   ├── io_config.yaml            # Cấu hình kết nối PostgreSQL cho Mage
│   ├── metadata.yaml             # Metadata dự án Mage
│   ├── data_loaders/             # get_extraction_window.py, load_source_files.py
│   ├── transformers/             # filter_incremental.py, standardize_and_validate.py
│   ├── data_exporters/           # load_stage.py (COPY theo chunk 250k dòng, idempotent)
│   ├── custom/                   # commit_watermark.py, run_dbt_transforms.py
│   └── pipelines/
│       └── yellow_taxi_ingestion/# Định nghĩa DAG pipeline tự động hóa ETL
├── mage/
│   └── run_etl.py                # Script CLI chạy Full Load / Incremental Load / Step / Status
├── dbt/                          # dbt Core project (nyc_taxi_bi)
│   ├── dbt_project.yml           # Cấu hình schema (clean_view, dds) và biến ngưỡng
│   ├── profiles.yml              # Kết nối Postgres (tự nhận biến môi trường container & host)
│   ├── macros/                   # generate_schema_name.sql
│   ├── models/
│   │   ├── staging/              # stg_yellow_trips_cleaned, stg_taxi_zones_cleaned, sources.yml
│   │   └── marts/                # 8 dim_*.sql, fact_yellow_taxi_trip.sql, schema.yml
│   └── tests/
│       ├── staging/              # 3 singular tests cho tầng clean_view
│       └── marts/                # 4 singular tests cho tầng dds (row count, balance, flags, speed)
├── sql/
│   ├── 02_dds_indexes.sql        # 8 chỉ mục tối ưu truy vấn trên dds.fact_yellow_taxi_trip
│   └── business_queries/         # 13 truy vấn nghiệm thu C1–C8 và E1–E5
├── data/
│   └── reference/                # Bản sao tham chiếu taxi_zone_lookup.csv & shapefile taxi_zones
├── docs/                         # Tài liệu kỹ thuật chi tiết Phase 2
│   ├── ingestion_guide.md        # Hướng dẫn vận hành Ingestion (Full & Incremental)
│   ├── cleaning_rules.md         # Quy tắc làm sạch và xử lý dị thường tầng clean_view
│   └── data_quality_report.md    # Báo cáo kiểm thử chất lượng dữ liệu & kết quả 13 truy vấn
└── deliverables/
    └── phase1/                   # Sản phẩm khảo sát dữ liệu & thiết kế mô hình DDS (Phase 1)
```

---

## 4. Hướng dẫn cài đặt & khởi chạy

### Yêu cầu trước khi cài đặt
- **Docker Desktop** (hỗ trợ `docker compose`)
- Đã tải bộ dữ liệu Yellow Taxi 2022–2023 và đặt đúng cấu trúc thư mục `dataset/` ở Mục 2

### Bước 1: Tạo tệp cấu hình `.env`

Tại thư mục gốc của dự án, sao chép `.env.example` thành `.env`:

```bash
# Linux / macOS / Git Bash
cp .env.example .env

# Windows PowerShell
Copy-Item .env.example .env
```

Nội dung mặc định trong `.env`:

```env
POSTGRES_DB=warehouse
POSTGRES_USER=labuser
POSTGRES_PASSWORD=password123
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
```

### Bước 2: Build image và khởi động cụm dịch vụ

```bash
docker compose build
docker compose up -d
docker compose ps
```

Đảm bảo container `lab-postgres` ở trạng thái `healthy` và `lab-mage` đang chạy.

| Dịch vụ | Container | Địa chỉ / Cổng (Host → Container) | Thông tin truy cập mặc định |
| :--- | :--- | :--- | :--- |
| **Mage AI** | `lab-mage` | `http://localhost:6789` (`6789:6789`) | Truy cập trực tiếp trên trình duyệt |
| **PostgreSQL 17** | `lab-postgres` | `localhost:5433` (`5433:5432`) | DB: `warehouse` / User: `labuser` / Pass: `password123` |
| **pgAdmin 4** | `lab-pgadmin` | `http://localhost:5051` (`5051:80`) | Email: `admin@admin.com` / Pass: `admin` |

> **Lưu ý về cổng PostgreSQL:** Từ máy host kết nối vào PostgreSQL qua cổng **`5433`** (để tránh xung đột cổng `5432` cài sẵn trên máy). Giữa các container trong Docker (`lab-mage`, `lab-pgadmin`) vẫn kết nối qua `postgres:5432`.

### Bước 3: Kiểm tra môi trường dbt và PostgreSQL

```bash
# Kiểm tra dbt trong container Mage
docker compose exec mage dbt --version

# Kiểm tra các schema đã được 01_init.sql khởi tạo (control, stage, clean_view, dds)
docker compose exec postgres psql -U labuser -d warehouse -c "\dn"
```

---

## 5. Hướng dẫn Vận hành Pipeline ETL

### Bước 5.1: Nạp danh mục Taxi Zones vào Staging

Trước khi chạy `dbt`, nạp bảng tra cứu 265 vùng vào `stage.raw_taxi_zones`:

```bash
docker compose exec mage python mage/run_etl.py --load-zones
```

### Bước 5.2: Nạp dữ liệu Trip Records (Chọn 1 trong 2 cách)

#### Cách A: Chạy tự động end-to-end trên Mage AI UI (khuyến nghị khi demo)
1. Mở giao diện Mage tại `http://localhost:6789`.
2. Chọn pipeline **`yellow_taxi_ingestion`** gồm 7 block nối tiếp:
   - `get_extraction_window` → đọc `LSET` từ `control.etl_watermark`, xác định cửa sổ trích xuất `CET`.
   - `load_source_files` → đọc tệp Parquet theo chế độ chạy và gắn lineage (`source_file_month`, `source_row_number`).
   - `filter_incremental` → lọc bản ghi thuộc cửa sổ trích xuất.
   - `standardize_and_validate` → chuẩn hóa tên cột `snake_case` và thứ tự cột theo `stage.raw_yellow_tripdata`.
   - `load_stage` → nạp theo lô 250.000 dòng bằng PostgreSQL `COPY` (hỗ trợ idempotent delete+insert).
   - `commit_watermark` → chỉ cập nhật `LSET = CET` và ghi `control.etl_batch_log` (`SUCCESS`) sau khi nạp `stage` thành công.
   - `run_dbt_transforms` → tự động gọi `dbt run` và `dbt test` để cập nhật `clean_view` và `dds`.
3. Cấu hình **Runtime Variables** trước khi chạy (hoặc tạo Trigger):
   - `load_mode`: `'incremental'` (mặc định — nạp tuần tự từng tháng mới hơn `LSET`) hoặc `'full'` (reset và nạp toàn bộ 24 tháng).
   - `batch_month`: `null` (tự động lấy tháng kế tiếp) hoặc chỉ định tháng cụ thể, ví dụ `'2022-01'`.

#### Cách B: Chạy qua CLI script `mage/run_etl.py`

```bash
# Xem trạng thái Watermark (LSET/CET), lịch sử batch và tiến độ các tháng trong Staging
docker compose exec mage python mage/run_etl.py --status

# Nạp tăng dần 1 tháng kế tiếp sau LSET (tiện demo từng bước)
docker compose exec mage python mage/run_etl.py --incremental-step

# Nạp tăng dần toàn bộ các tháng mới hơn LSET
docker compose exec mage python mage/run_etl.py --incremental-load

# Nạp toàn bộ từ đầu (TRUNCATE stage, nạp lại Taxi Zones + 24 tháng Parquet)
docker compose exec mage python mage/run_etl.py --full-load

# Nạp thủ công một tháng cụ thể
docker compose exec mage python mage/run_etl.py --month 2022-01

# Xóa sạch Staging và đưa Watermark về 1900-01-01
docker compose exec mage python mage/run_etl.py --reset
```

### Bước 5.3: Chạy chuyển đổi dbt (`clean_view` → `dds`) và tạo Index

Nếu nạp dữ liệu bằng `mage/run_etl.py` (không chạy qua block `run_dbt_transforms` của Mage), chạy các lệnh sau để xây dựng tầng `clean_view` và `dds`:

```bash
# Chạy toàn bộ models (staging -> clean_view và marts -> dds)
docker compose exec mage dbt run --project-dir /home/src/dbt --profiles-dir /home/src/dbt

# (Tùy chọn) Chạy riêng từng tầng
docker compose exec mage dbt run --select staging --project-dir /home/src/dbt --profiles-dir /home/src/dbt
docker compose exec mage dbt run --select marts --project-dir /home/src/dbt --profiles-dir /home/src/dbt

# (Tùy chọn) Chạy lại toàn bộ bảng Fact (full-refresh)
docker compose exec mage dbt run --select fact_yellow_taxi_trip --full-refresh --project-dir /home/src/dbt --profiles-dir /home/src/dbt
```

Tạo 8 chỉ mục tối ưu hóa truy vấn trên bảng Fact `dds.fact_yellow_taxi_trip`:

```bash
# Linux / macOS / Git Bash
docker compose exec -T postgres psql -U labuser -d warehouse < sql/02_dds_indexes.sql

# Windows PowerShell
Get-Content sql/02_dds_indexes.sql | docker compose exec -T postgres psql -U labuser -d warehouse
```

---

## 6. Kiểm thử Chất lượng Dữ liệu & Truy vấn Nghiệm thu

### 6.1. Chạy toàn bộ bộ kiểm thử tự động trên dbt

```bash
docker compose exec mage dbt test --project-dir /home/src/dbt --profiles-dir /home/src/dbt
```

Bộ kiểm thử bao gồm:
- **Generic Schema Tests** (`dbt/models/staging/schema.yml`, `dbt/models/marts/schema.yml`):
  - `unique` & `not_null` cho khóa chính của toàn bộ 8 bảng Dimension và bảng Fact (`trip_record_key`).
  - `relationships` kiểm tra toàn vẹn tham chiếu cho tất cả **11 khóa ngoại** của `fact_yellow_taxi_trip` (0 bản ghi mồ côi).
  - `accepted_values` cho các cờ logic (`is_in_study_period`, `is_negative_charge`, `is_valid_duration`, `is_valid_for_tip_ratio`, `is_valid_for_speed`) và thuộc tính phân loại.
- **Custom Singular Tests — Staging (`dbt/tests/staging/`):**
  - `assert_stg_trips_row_count_matches_stage.sql`: đối soát số dòng `clean_view = stage` theo từng tháng.
  - `assert_stg_trips_unique_source_row.sql`: đảm bảo duy nhất theo `(source_file_month, source_row_number)`.
  - `assert_stg_trips_derived_logic.sql`: kiểm tra logic thời lượng, vận tốc (`<= 120 mph`), khóa ngày/giờ và cờ nghiệp vụ.
- **Custom Singular Tests — Marts (`dbt/tests/marts/`):**
  - `assert_fact_count_matches_stage.sql`: đối soát Zero Data Loss (`stage = fact`) theo từng tháng.
  - `assert_revenue_components_balance.sql`: kiểm tra cân đối kế toán giữa `total_amount` và 8 cấu phần cước phí.
  - `assert_study_period_flags.sql`: kiểm tra cờ phạm vi nghiên cứu `[2022-01-01, 2024-01-01)`.
  - `assert_duration_and_speed_logic.sql`: đảm bảo `speed_mph IS NULL` khi `duration_minutes <= 0`.

### 6.2. Chạy 13 truy vấn nghiệp vụ (C1–C8, E1–E5)

Toàn bộ 13 truy vấn phân tích nằm trong `sql/business_queries/`. Ví dụ chạy truy vấn `C1`:

```bash
# Linux / macOS / Git Bash
docker compose exec -T postgres psql -U labuser -d warehouse < sql/business_queries/q_c1_trips_passengers_by_date.sql

# Windows PowerShell
Get-Content sql/business_queries/q_c1_trips_passengers_by_date.sql | docker compose exec -T postgres psql -U labuser -d warehouse
```

---

## 7. Tài liệu Kỹ thuật Chi tiết

- **Vận hành Ingestion & Watermark:** [`docs/ingestion_guide.md`](docs/ingestion_guide.md)
- **Quy tắc làm sạch & xử lý dị thường (`clean_view`):** [`docs/cleaning_rules.md`](docs/cleaning_rules.md)
- **Báo cáo kiểm thử QA & kết quả 13 truy vấn:** [`docs/data_quality_report.md`](docs/data_quality_report.md)
- **Hồ sơ phân tích & thiết kế DDS (Phase 1):** [`deliverables/phase1/README.md`](deliverables/phase1/README.md)

---

