#!/usr/bin/env python3
"""
NYC Yellow Taxi ETL Runner Script (Phase 2)
Phụ trách: Trần Lê Trung Trực
Mô tả: Hỗ trợ cả 2 cơ chế FULL LOAD và INCREMENTAL LOAD:
       - Full Load: Truncate staging, reset watermark, nạp toàn bộ 24 tháng từ đầu.
       - Incremental Load: Đọc LSET từ control.etl_watermark, xác định và chỉ nạp các tháng mới hơn LSET.
       - Incremental Step: Nạp chính xác 1 batch tháng tiếp theo sau LSET (phục vụ demo).
"""

import argparse
from datetime import datetime, timezone
from io import StringIO
import os
from pathlib import Path
import sys
import pandas as pd
import psycopg2

MONTHS_2022_2023 = [
    f"{year}-{month:02d}"
    for year in (2022, 2023)
    for month in range(1, 13)
]

COLUMN_MAPPING = {
    'vendorid': 'vendor_id',
    'tpep_pickup_datetime': 'tpep_pickup_datetime',
    'tpep_dropoff_datetime': 'tpep_dropoff_datetime',
    'passenger_count': 'passenger_count',
    'trip_distance': 'trip_distance',
    'ratecodeid': 'rate_code_id',
    'store_and_fwd_flag': 'store_and_fwd_flag',
    'pulocationid': 'pu_location_id',
    'dolocationid': 'do_location_id',
    'payment_type': 'payment_type',
    'fare_amount': 'fare_amount',
    'extra': 'extra',
    'mta_tax': 'mta_tax',
    'tip_amount': 'tip_amount',
    'tolls_amount': 'tolls_amount',
    'improvement_surcharge': 'improvement_surcharge',
    'total_amount': 'total_amount',
    'congestion_surcharge': 'congestion_surcharge',
    'airport_fee': 'airport_fee',
}

TARGET_COLUMNS = [
    'source_file_month',
    'source_row_number',
    'vendor_id',
    'tpep_pickup_datetime',
    'tpep_dropoff_datetime',
    'passenger_count',
    'trip_distance',
    'rate_code_id',
    'store_and_fwd_flag',
    'pu_location_id',
    'do_location_id',
    'payment_type',
    'fare_amount',
    'extra',
    'mta_tax',
    'tip_amount',
    'tolls_amount',
    'improvement_surcharge',
    'total_amount',
    'congestion_surcharge',
    'airport_fee',
]


def get_db_connection():
    """Tạo kết nối tới PostgreSQL sử dụng biến môi trường."""
    host = os.getenv('POSTGRES_HOST', 'postgres')
    port = int(os.getenv('POSTGRES_PORT', 5432))
    dbname = os.getenv('POSTGRES_DB', 'warehouse')
    user = os.getenv('POSTGRES_USER', 'labuser')
    password = os.getenv('POSTGRES_PASSWORD', 'password123')

    if not os.path.exists('/.dockerenv'):
        if host == 'postgres':
            host = 'localhost'
        port = int(os.getenv('POSTGRES_HOST_PORT', 5433))

    return psycopg2.connect(
        dbname=dbname,
        user=user,
        password=password,
        host=host,
        port=port,
    )


def load_taxi_zones(dataset_dir: Path):
    """Nạp danh mục Taxi Zones vào stage.raw_taxi_zones."""
    csv_candidates = [
        dataset_dir / 'taxi+_zone_lookup.csv',
        dataset_dir / 'taxi_zones' / 'taxi+_zone_lookup.csv',
        Path('dataset/taxi+_zone_lookup.csv'),
        Path('/home/src/dataset/taxi+_zone_lookup.csv'),
    ]
    csv_file = next((f for f in csv_candidates if f.exists()), None)
    if not csv_file:
        raise FileNotFoundError(f"Không tìm thấy file taxi+_zone_lookup.csv trong các đường dẫn: {csv_candidates}")

    print(f"[*] Đang đọc danh mục Taxi Zones từ: {csv_file}")
    df = pd.read_csv(csv_file)
    df.columns = [c.lower() for c in df.columns]
    df = df.rename(columns={'locationid': 'location_id', 'service_zone': 'service_zone'})

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("TRUNCATE TABLE stage.raw_taxi_zones;")
        buffer = StringIO()
        df[['location_id', 'borough', 'zone', 'service_zone']].to_csv(buffer, index=False, header=False, sep='\t', na_rep='\\N')
        buffer.seek(0)
        cur.copy_expert("COPY stage.raw_taxi_zones (location_id, borough, zone, service_zone) FROM STDIN WITH (FORMAT text, NULL '\\N');", buffer)
        conn.commit()
        print(f"[✓] Đã nạp thành công {len(df):,} zones vào stage.raw_taxi_zones.")
    finally:
        cur.close()
        conn.close()


def find_parquet_file(dataset_dir: Path, batch_month: str) -> Path:
    """Tìm file parquet cho tháng chỉ định."""
    candidates = [
        dataset_dir / 'trip_data' / f'yellow_tripdata_{batch_month}.parquet',
        Path(f'dataset/trip_data/yellow_tripdata_{batch_month}.parquet'),
        Path(f'/home/src/dataset/trip_data/yellow_tripdata_{batch_month}.parquet'),
    ]
    for c in candidates:
        if c.exists():
            return c
    raise FileNotFoundError(f"Không tìm thấy file parquet cho tháng {batch_month} trong {candidates}")


def get_current_watermark():
    """Lấy mốc LSET hiện tại từ control.etl_watermark."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT lset FROM control.etl_watermark WHERE pipeline_name = 'yellow_taxi_ingestion';")
        row = cur.fetchone()
        return row[0] if row else None
    finally:
        cur.close()
        conn.close()


def reset_staging():
    """Reset sạch sẽ bảng Staging và Watermark về trạng thái khởi đầu."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        print("[*] Đang thực hiện RESET: TRUNCATE stage.raw_yellow_tripdata và đưa Watermark về 1900-01-01...")
        cur.execute("TRUNCATE TABLE stage.raw_yellow_tripdata;")
        cur.execute("""
            UPDATE control.etl_watermark
            SET lset = '1900-01-01 00:00:00', cet = '1900-01-01 00:00:00',
                last_status = 'INIT', updated_at = CURRENT_TIMESTAMP
            WHERE pipeline_name = 'yellow_taxi_ingestion';
        """)
        conn.commit()
        print("[✓] Đã RESET thành công Staging và Watermark.")
    finally:
        cur.close()
        conn.close()


def load_single_month(dataset_dir: Path, batch_month: str, load_type='INCREMENTAL', dry_run=False):
    """Thực thi chu trình nạp 1 tháng: Ingestion -> Transform -> Load Stage -> Commit Watermark."""
    file_path = find_parquet_file(dataset_dir, batch_month)
    print(f"\n=======================================================")
    print(f"[*] [{load_type}] Bắt đầu xử lý Batch: {batch_month} ({file_path.name})")
    print(f"=======================================================")

    df = pd.read_parquet(file_path, engine='pyarrow')
    rows_read = len(df)
    print(f"[*] Đã đọc {rows_read:,} dòng từ nguồn.")

    # 1. Standardize & Add Lineage
    df.columns = [col.lower() for col in df.columns]
    df = df.rename(columns=COLUMN_MAPPING)
    df['source_file_month'] = batch_month
    df['source_row_number'] = range(1, rows_read + 1)

    for col in TARGET_COLUMNS:
        if col not in df.columns:
            df[col] = None
    df = df[TARGET_COLUMNS]

    if dry_run:
        print(f"[DRY-RUN] Chuẩn hóa thành công {len(df):,} dòng cho tháng {batch_month}. Không ghi CSDL.")
        return rows_read

    # 2. Database Load & Watermark Commit
    year, month = map(int, batch_month.split('-'))
    cet_str = f"{year:04d}-{month:02d}-01 00:00:00"

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # Idempotency: xóa dữ liệu tháng cũ nếu đã tồn tại để tránh trùng lặp
        cur.execute("DELETE FROM stage.raw_yellow_tripdata WHERE source_file_month = %s;", (batch_month,))
        
        # Fast copy streaming
        buffer = StringIO()
        df.to_csv(buffer, index=False, header=False, sep='\t', na_rep='\\N')
        buffer.seek(0)
        
        cols = list(df.columns)
        copy_sql = f"COPY stage.raw_yellow_tripdata ({', '.join(cols)}) FROM STDIN WITH (FORMAT text, NULL '\\N');"
        cur.copy_expert(copy_sql, buffer)

        # Commit Watermark & Batch Log
        cur.execute("""
            UPDATE control.etl_watermark
            SET lset = %s, cet = %s, last_status = 'SUCCESS', updated_at = CURRENT_TIMESTAMP
            WHERE pipeline_name = 'yellow_taxi_ingestion';
        """, (cet_str, cet_str))

        cur.execute("""
            INSERT INTO control.etl_batch_log (
                pipeline_name, file_name, source_file_month, load_type,
                rows_read, rows_inserted, status, completed_at
            )
            VALUES ('yellow_taxi_ingestion', %s, %s, %s, %s, %s, 'SUCCESS', CURRENT_TIMESTAMP);
        """, (file_path.name, batch_month, load_type, rows_read, len(df)))

        conn.commit()
        print(f"[✓] Nạp thành công {len(df):,} dòng vào stage.raw_yellow_tripdata.")
        print(f"[✓] Đã cập nhật Watermark LSET mới = {cet_str} | Load Type: {load_type}")
    except Exception as e:
        conn.rollback()
        try:
            cur.execute("""
                INSERT INTO control.etl_batch_log (
                    pipeline_name, file_name, source_file_month, load_type,
                    rows_read, rows_inserted, status, error_message, completed_at
                )
                VALUES ('yellow_taxi_ingestion', %s, %s, %s, %s, 0, 'FAILED', %s, CURRENT_TIMESTAMP);
            """, (file_path.name, batch_month, load_type, rows_read, str(e)))
            conn.commit()
        except:
            pass
        raise e
    finally:
        cur.close()
        conn.close()

    return rows_read


def run_full_load(dataset_dir: Path, dry_run=False):
    """Quy trình FULL LOAD: Làm mới toàn bộ Staging và nạp lại toàn bộ 24 tháng."""
    print("\n*******************************************************")
    print(">>> BẮT ĐẦU QUY TRÌNH FULL LOAD (INITIAL LOAD) <<<")
    print("*******************************************************")
    if not dry_run:
        reset_staging()
        load_taxi_zones(dataset_dir)

    total_rows = 0
    for m in MONTHS_2022_2023:
        total_rows += load_single_month(dataset_dir, m, load_type='FULL', dry_run=dry_run)

    print(f"\n[✓] HOÀN TẤT FULL LOAD TOÀN BỘ 24 THÁNG! Tổng số dòng: {total_rows:,}")


def run_incremental_load(dataset_dir: Path, single_step=False, dry_run=False):
    """Quy trình INCREMENTAL LOAD: Chỉ nạp các tháng mới hơn mốc LSET hiện tại."""
    print("\n*******************************************************")
    print(">>> BẮT ĐẦU QUY TRÌNH INCREMENTAL LOAD <<<")
    print("*******************************************************")
    
    lset = get_current_watermark()
    print(f"[*] Mốc Watermark hiện tại (LSET): {lset}")

    # Tìm các tháng có mốc thời gian lớn hơn LSET
    pending_months = []
    for m in MONTHS_2022_2023:
        y, mon = map(int, m.split('-'))
        batch_dt = datetime(y, mon, 1)
        if lset is None or batch_dt > lset:
            pending_months.append(m)

    if not pending_months:
        print("[✓] Hệ thống đã cập nhật mới nhất! Không có batch dữ liệu mới nào cần nạp.")
        return

    print(f"[*] Danh sách {len(pending_months)} batch cần nạp tăng dần: {pending_months}")
    if single_step:
        pending_months = pending_months[:1]
        print(f"[*] Chế độ Incremental Step: Chỉ nạp 1 batch tiếp theo: {pending_months[0]}")

    total_rows = 0
    for m in pending_months:
        total_rows += load_single_month(dataset_dir, m, load_type='INCREMENTAL', dry_run=dry_run)

    print(f"\n[✓] HOÀN TẤT INCREMENTAL LOAD! Đã nạp thêm: {total_rows:,} dòng qua {len(pending_months)} batch.")


def show_status():
    """Hiển thị trạng thái Watermark và tổng số dòng hiện có trong CSDL."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        print("\n=== TRẠNG THÁI WATERMARK (control.etl_watermark) ===")
        cur.execute("SELECT pipeline_name, lset, cet, last_status, updated_at FROM control.etl_watermark;")
        for row in cur.fetchall():
            print(f"Pipeline: {row[0]} | LSET: {row[1]} | CET: {row[2]} | Status: {row[3]} | Updated: {row[4]}")

        print("\n=== LỊCH SỬ CÁC BATCH GẦN NHẤT (control.etl_batch_log) ===")
        cur.execute("""
            SELECT batch_id, source_file_month, load_type, rows_read, rows_inserted, status, completed_at
            FROM control.etl_batch_log
            ORDER BY batch_id DESC
            LIMIT 10;
        """)
        for r in cur.fetchall():
            print(f"Batch #{r[0]}: Tháng {r[1]} | Kiểu: {r[2]} | Đọc: {r[3]:,} | Insert: {r[4]:,} | Trạng thái: {r[5]} | Lúc: {r[6]}")

        print("\n=== TIẾN ĐỘ THEO TỪNG THÁNG TRONG STAGING (stage.raw_yellow_tripdata) ===")
        cur.execute("""
            SELECT source_file_month, COUNT(*) AS row_count
            FROM stage.raw_yellow_tripdata
            GROUP BY source_file_month
            ORDER BY source_file_month;
        """)
        rows = cur.fetchall()
        total_rows = sum(r[1] for r in rows)
        for r in rows:
            print(f"Tháng {r[0]}: {r[1]:>10,} dòng")
        print(f"----------------------------------------")
        print(f"Tổng cộng trong Staging: {total_rows:>10,} dòng ({len(rows)}/24 tháng)")

        cur.execute("SELECT COUNT(*) FROM stage.raw_taxi_zones;")
        zones_count = cur.fetchone()[0]
        print(f"Taxi Zones trong stage: {zones_count} zones")
    finally:
        cur.close()
        conn.close()


def main():
    parser = argparse.ArgumentParser(description="NYC Yellow Taxi ETL Ingestion Runner (Full & Incremental)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--full-load', action='store_true', help='Thực hiện FULL LOAD: truncate staging và nạp toàn bộ 24 tháng')
    group.add_argument('--incremental-load', action='store_true', help='Thực hiện INCREMENTAL LOAD: chỉ nạp các tháng mới hơn LSET')
    group.add_argument('--incremental-step', action='store_true', help='Thực hiện nạp 1 batch tiếp theo sau LSET (phục vụ demo từng bước)')
    group.add_argument('--month', type=str, help='Nạp 1 tháng cụ thể (VD: 2022-01)')
    group.add_argument('--load-zones', action='store_true', help='Nạp danh mục Taxi Zones vào stage.raw_taxi_zones')
    group.add_argument('--status', action='store_true', help='Xem trạng thái Watermark và số lượng dòng hiện tại')
    group.add_argument('--reset', action='store_true', help='Xóa sạch dữ liệu Staging và reset Watermark về ban đầu')
    
    parser.add_argument('--dry-run', action='store_true', help='Chạy thử nghiệm đọc & chuẩn hóa không ghi CSDL')
    parser.add_argument('--dataset-dir', type=Path, default=Path('dataset'), help='Đường dẫn thư mục dataset')

    args = parser.parse_args()

    # Tải biến môi trường từ file .env nếu có
    if Path('.env').exists():
        with open('.env', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    os.environ.setdefault(k.strip(), v.strip())

    if args.status:
        show_status()
    elif args.reset:
        reset_staging()
    elif args.load_zones:
        load_taxi_zones(args.dataset_dir)
    elif args.month:
        load_single_month(args.dataset_dir, args.month, load_type='MANUAL', dry_run=args.dry_run)
    elif args.full_load:
        run_full_load(args.dataset_dir, dry_run=args.dry_run)
    elif args.incremental_load:
        run_incremental_load(args.dataset_dir, single_step=False, dry_run=args.dry_run)
    elif args.incremental_step:
        run_incremental_load(args.dataset_dir, single_step=True, dry_run=args.dry_run)


if __name__ == '__main__':
    main()
