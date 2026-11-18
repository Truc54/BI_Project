from os import path
from pathlib import Path
import pandas as pd
if 'data_loader' not in globals():
    from mage_ai.data_preparation.decorators import data_loader

MONTHS_2022_2023 = [
    f"{year}-{month:02d}"
    for year in (2022, 2023)
    for month in range(1, 13)
]

@data_loader
def load_source_files(*args, **kwargs):
    """
    Đọc dữ liệu nguồn Parquet theo chế độ nạp (Full Load hoặc Incremental Load).
    """
    load_mode = str(kwargs.get('load_mode', 'incremental')).lower()
    batch_month = kwargs.get('batch_month')

    if load_mode == 'full':
        months_to_load = MONTHS_2022_2023
        print(f"[*] [FULL LOAD] Đang chuẩn bị đọc toàn bộ 24 tháng...")
    else:
        # Incremental: nếu có chỉ định batch_month thì lấy, nếu không tự động tìm mẻ tiếp theo
        if batch_month:
            months_to_load = [batch_month]
        else:
            try:
                from datetime import datetime
                from mage_ai.settings.repo import get_repo_path
                from mage_ai.io.config import ConfigFileLoader
                import psycopg2
                config_path = path.join(get_repo_path(), 'io_config.yaml')
                config = ConfigFileLoader(config_path, 'default').config
                conn = psycopg2.connect(
                    dbname=config.get('POSTGRES_DBNAME'),
                    user=config.get('POSTGRES_USER'),
                    password=config.get('POSTGRES_PASSWORD'),
                    host=config.get('POSTGRES_HOST'),
                    port=config.get('POSTGRES_PORT'),
                )
                cur = conn.cursor()
                cur.execute("SELECT lset FROM control.etl_watermark WHERE pipeline_name = 'yellow_taxi_ingestion';")
                row = cur.fetchone()
                cur.close()
                conn.close()
                lset = row[0] if row else None

                target = []
                for m in MONTHS_2022_2023:
                    y, mon = map(int, m.split('-'))
                    if lset is None or datetime(y, mon, 1) > lset:
                        target.append(m)
                months_to_load = [target[0]] if target else ['2022-01']
            except Exception:
                months_to_load = ['2022-01']

        print(f"[*] [INCREMENTAL LOAD] Đang chuẩn bị đọc batch: {months_to_load}")

    dfs = []
    total_read = 0
    for m in months_to_load:
        candidates = [
            Path(f"/home/src/dataset/trip_data/yellow_tripdata_{m}.parquet"),
            Path(f"dataset/trip_data/yellow_tripdata_{m}.parquet"),
        ]
        file_path = next((p for p in candidates if p.exists()), None)
        if not file_path:
            print(f"[!] Không tìm thấy file Parquet cho tháng {m}")
            continue

        print(f"[*] Đọc file: {file_path.name}")
        df = pd.read_parquet(file_path, engine='pyarrow')
        df['source_file_month'] = m
        df['source_row_number'] = range(1, len(df) + 1)
        dfs.append(df)
        total_read += len(df)

    if not dfs:
        raise FileNotFoundError("Không tìm thấy tệp Parquet nào phù hợp!")

    combined_df = pd.concat(dfs, ignore_index=True) if len(dfs) > 1 else dfs[0]
    print(f"[✓] Đọc thành công {len(combined_df):,} dòng từ nguồn.")

    return {
        'df': combined_df,
        'rows_read': len(combined_df),
        'months': months_to_load,
        'load_mode': load_mode,
        'file_name': f"yellow_tripdata_{months_to_load[0]}.parquet" if len(months_to_load) == 1 else "all_24_months.parquet",
    }
