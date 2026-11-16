from datetime import datetime
from os import path
import psycopg2
from mage_ai.settings.repo import get_repo_path
from mage_ai.io.config import ConfigFileLoader
if 'custom' not in globals():
    from mage_ai.data_preparation.decorators import custom

@custom
def commit_watermark(payload, *args, **kwargs):
    """
    Cập nhật watermark và ghi nhật ký tiến trình (Batch Log) sau khi nạp thành công:
    - FULL LOAD: LSET cập nhật lên mốc kết thúc '2023-12-01 00:00:00', log ghi nhận 'FULL'.
    - INCREMENTAL LOAD: LSET cập nhật theo CET của batch vừa nạp, log ghi nhận 'INCREMENTAL'.
    """
    load_mode = payload.get('load_mode', 'incremental')
    cet = payload['cet']
    rows_read = payload.get('rows_read', 0)
    rows_inserted = payload.get('rows_inserted', 0)
    file_name = payload.get('file_name', 'parquet_batch')
    batch_month = payload.get('batch_month', '2022-01')

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
        # 1. Cập nhật control.etl_watermark
        cursor.execute("""
            UPDATE control.etl_watermark
            SET lset = %s,
                cet = %s,
                last_status = 'SUCCESS',
                updated_at = CURRENT_TIMESTAMP
            WHERE pipeline_name = 'yellow_taxi_ingestion';
        """, (cet, cet))

        # 2. Ghi nhật ký vào control.etl_batch_log
        cursor.execute("""
            INSERT INTO control.etl_batch_log (
                pipeline_name, file_name, source_file_month, load_type,
                rows_read, rows_inserted, status, completed_at
            )
            VALUES (
                'yellow_taxi_ingestion', %s, %s, %s,
                %s, %s, 'SUCCESS', CURRENT_TIMESTAMP
            );
        """, (file_name, batch_month, load_mode.upper(), rows_read, rows_inserted))

        conn.commit()
        print(f"[✓] Commit Watermark thành công! LSET mới = {cet} | Ghi log mẻ nạp {load_mode.upper()}.")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cursor.close()
        conn.close()

    return {
        'status': 'SUCCESS',
        'load_mode': load_mode,
        'committed_watermark': cet,
        'rows_inserted': rows_inserted,
    }
