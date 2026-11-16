from io import StringIO
from os import path
import psycopg2
from mage_ai.settings.repo import get_repo_path
from mage_ai.io.config import ConfigFileLoader
if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter

@data_exporter
def load_stage(payload, *args, **kwargs):
    """
    Nạp dữ liệu vào stage.raw_yellow_tripdata:
    - FULL LOAD: TRUNCATE bảng trước khi nạp toàn bộ.
    - INCREMENTAL LOAD: Xóa batch cũ tương ứng và nạp thêm batch mới (Idempotent Append).
    """
    df = payload['df']
    load_mode = payload.get('load_mode', 'incremental')
    target_months = payload.get('target_months', [])

    if df.empty:
        print("[!] DataFrame rỗng, không có dữ liệu để ghi CSDL.")
        return payload

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

    try:
        if load_mode == 'full':
            print("[*] [FULL LOAD] Đang TRUNCATE TABLE stage.raw_yellow_tripdata để làm mới hoàn toàn...")
            cursor.execute("TRUNCATE TABLE stage.raw_yellow_tripdata;")
        else:
            # Incremental: Xóa các tháng có trong đợt nạp này để tránh trùng dòng khi chạy lại
            months_to_clear = list(df['source_file_month'].unique())
            cursor.execute("DELETE FROM stage.raw_yellow_tripdata WHERE source_file_month = ANY(%s);", (months_to_clear,))
            print(f"[*] [INCREMENTAL LOAD] Đã dọn dẹp các tháng cũ (nếu có): {months_to_clear}")

        # Streaming copy tốc độ cao
        buffer = StringIO()
        df.to_csv(buffer, index=False, header=False, sep='\t', na_rep='\\N')
        buffer.seek(0)

        cols = list(df.columns)
        copy_sql = f"""
            COPY stage.raw_yellow_tripdata ({', '.join(cols)})
            FROM STDIN WITH (FORMAT text, NULL '\\N');
        """
        cursor.copy_expert(copy_sql, buffer)
        conn.commit()

        print(f"[✓] Đã nạp thành công {len(df):,} dòng vào stage.raw_yellow_tripdata (Chế độ: {load_mode.upper()}).")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cursor.close()
        conn.close()

    return payload
