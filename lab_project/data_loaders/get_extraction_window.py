from os import path
from datetime import datetime
import psycopg2
from mage_ai.settings.repo import get_repo_path
from mage_ai.io.config import ConfigFileLoader
if 'data_loader' not in globals():
    from mage_ai.data_preparation.decorators import data_loader

MONTHS_2022_2023 = [
    f"{year}-{month:02d}"
    for year in (2022, 2023)
    for month in range(1, 13)
]

@data_loader
def get_extraction_window(*args, **kwargs):
    """
    Xác định chế độ nạp và cửa sổ trích xuất (Extraction Window).
    
    Hỗ trợ cả 2 cơ chế qua biến runtime `load_mode`:
    1. 'full': FULL LOAD - nạp toàn bộ 24 tháng (LSET khởi tạo về 1900-01-01).
    2. 'incremental': INCREMENTAL LOAD - tự động đọc LSET từ CSDL và chỉ nạp các tháng mới.
    """
    # 1. Đọc chế độ chạy từ runtime variable (mặc định là 'incremental')
    load_mode = str(kwargs.get('load_mode', 'incremental')).lower()

    # 2. Đọc LSET hiện tại từ bảng control.etl_watermark
    config_path = path.join(get_repo_path(), 'io_config.yaml')
    config = ConfigFileLoader(config_path, 'default').config

    conn = psycopg2.connect(
        dbname=config.get('POSTGRES_DBNAME'),
        user=config.get('POSTGRES_USER'),
        password=config.get('POSTGRES_PASSWORD'),
        host=config.get('POSTGRES_HOST'),
        port=config.get('POSTGRES_PORT'),
    )
    cursor = conn.cursor()
    cursor.execute("""
        SELECT lset, cet, last_status
        FROM control.etl_watermark
        WHERE pipeline_name = 'yellow_taxi_ingestion';
    """)
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    lset = row[0] if row else None

    # 3. Phân nhánh logic theo chế độ:
    if load_mode == 'full':
        print("\n=======================================================")
        print(">>> CHẾ ĐỘ: FULL LOAD (Nạp toàn bộ 24 tháng) <<<")
        print("=======================================================")
        target_months = MONTHS_2022_2023
        lset_str = '1900-01-01 00:00:00'
        cet_str = '2023-12-01 00:00:00'
    else:
        print("\n=======================================================")
        print(">>> CHẾ ĐỘ: INCREMENTAL LOAD (Nạp tăng dần theo Watermark) <<<")
        print("=======================================================")
        
        # Nếu người dùng truyền 1 tháng cụ thể để nạp step-by-step
        batch_override = kwargs.get('batch_month') or kwargs.get('cet_override')
        if batch_override:
            target_months = [batch_override]
            y, m = map(int, batch_override.split('-'))
            cet_str = f"{y:04d}-{m:02d}-01 00:00:00"
            lset_str = str(lset) if lset else '1900-01-01 00:00:00'
        else:
            # Tự động tìm các tháng chưa nạp (tháng có thời điểm > LSET)
            target_months = []
            for m in MONTHS_2022_2023:
                y, mon = map(int, m.split('-'))
                batch_dt = datetime(y, mon, 1)
                if lset is None or batch_dt > lset:
                    target_months.append(m)

            if target_months:
                # Nạp batch tháng tiếp theo
                target_months = [target_months[0]]
                y, m = map(int, target_months[0].split('-'))
                cet_str = f"{y:04d}-{m:02d}-01 00:00:00"
            else:
                cet_str = str(lset)

            lset_str = str(lset) if lset else '1900-01-01 00:00:00'

        print(f"[*] Mốc LSET hiện tại: {lset_str} -> CET: {cet_str} | Batch cần nạp: {target_months}")

    return {
        'load_mode': load_mode,
        'lset': lset_str,
        'cet': cet_str,
        'target_months': target_months,
    }
