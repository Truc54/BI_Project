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
        # Incremental: nếu có chỉ định batch_month thì lấy, nếu không lấy từ danh sách
        months_to_load = [batch_month] if batch_month else ['2022-01']
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
