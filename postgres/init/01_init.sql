-- =============================================================================
-- 01_init.sql: Khởi tạo Schemas và Bảng cho NYC Yellow Taxi BI Project
-- =============================================================================

-- 1. Tạo các schemas chuẩn theo kiến trúc dữ liệu của dự án
CREATE SCHEMA IF NOT EXISTS control;
CREATE SCHEMA IF NOT EXISTS stage;
CREATE SCHEMA IF NOT EXISTS clean_view;
CREATE SCHEMA IF NOT EXISTS dds;

-- =============================================================================
-- 2. Schema CONTROL: Quản lý siêu dữ liệu nạp và cơ chế Watermark
-- =============================================================================

-- Bảng lưu trữ Watermark (LSET và CET) phục vụ nạp tăng dần
CREATE TABLE IF NOT EXISTS control.etl_watermark (
    pipeline_name VARCHAR(100) PRIMARY KEY,
    lset TIMESTAMP NOT NULL,
    cet TIMESTAMP NOT NULL,
    last_status VARCHAR(20) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Khởi tạo mốc ban đầu cho pipeline yellow_taxi_ingestion
INSERT INTO control.etl_watermark (pipeline_name, lset, cet, last_status)
VALUES ('yellow_taxi_ingestion', '1900-01-01 00:00:00', '1900-01-01 00:00:00', 'INIT')
ON CONFLICT (pipeline_name) DO NOTHING;

-- Bảng ghi nhật ký chi tiết từng mẻ nạp (Batch Log)
CREATE TABLE IF NOT EXISTS control.etl_batch_log (
    batch_id SERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    source_file_month VARCHAR(7) NOT NULL,
    load_type VARCHAR(20) DEFAULT 'INCREMENTAL', -- 'FULL' hoặc 'INCREMENTAL'
    rows_read BIGINT DEFAULT 0,
    rows_inserted BIGINT DEFAULT 0,
    status VARCHAR(20) NOT NULL, -- 'RUNNING', 'SUCCESS', 'FAILED'
    error_message TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- =============================================================================
-- 3. Schema STAGE: Lưu trữ dữ liệu thô từ nguồn (Raw Landing)
-- =============================================================================

-- Bảng Staging danh mục tra cứu vùng Taxi (265 zones)
CREATE TABLE IF NOT EXISTS stage.raw_taxi_zones (
    location_id INT PRIMARY KEY,
    borough VARCHAR(50),
    zone VARCHAR(100),
    service_zone VARCHAR(50)
);

-- Bảng Staging cuốc xe Yellow Taxi (giữ nguyên 19 trường thô + 2 trường lineage)
CREATE TABLE IF NOT EXISTS stage.raw_yellow_tripdata (
    source_file_month VARCHAR(7) NOT NULL,
    source_row_number BIGINT NOT NULL,
    vendor_id INT,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count DOUBLE PRECISION,
    trip_distance DOUBLE PRECISION,
    rate_code_id DOUBLE PRECISION,
    store_and_fwd_flag VARCHAR(10),
    pu_location_id INT,
    do_location_id INT,
    payment_type BIGINT,
    fare_amount DOUBLE PRECISION,
    extra DOUBLE PRECISION,
    mta_tax DOUBLE PRECISION,
    tip_amount DOUBLE PRECISION,
    tolls_amount DOUBLE PRECISION,
    improvement_surcharge DOUBLE PRECISION,
    total_amount DOUBLE PRECISION,
    congestion_surcharge DOUBLE PRECISION,
    airport_fee DOUBLE PRECISION,
    PRIMARY KEY (source_file_month, source_row_number)
);

-- Index hỗ trợ truy vấn lọc theo tháng trên bảng Staging
CREATE INDEX IF NOT EXISTS idx_stg_trip_month ON stage.raw_yellow_tripdata (source_file_month);
