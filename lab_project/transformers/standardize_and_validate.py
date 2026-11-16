import pandas as pd
if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer

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

@transformer
def standardize_and_validate(payload, *args, **kwargs):
    """
    Chuẩn hóa tên cột, kiểu dữ liệu và thứ tự cột theo đặc tả của schema stage.
    """
    df = payload['df'].copy()
    load_mode = payload.get('load_mode', 'incremental')

    # 1. Chuyển toàn bộ tên cột thành chữ thường
    df.columns = [col.lower() for col in df.columns]

    # 2. Đổi tên theo chuẩn schema
    df = df.rename(columns=COLUMN_MAPPING)

    # 3. Đảm bảo có đủ các cột đích
    for col in TARGET_COLUMNS:
        if col not in df.columns:
            df[col] = None

    # 4. Sắp xếp lại theo đúng thứ tự cột của bảng stage.raw_yellow_tripdata
    df = df[TARGET_COLUMNS]

    print(f"[✓] Chuẩn hóa hoàn tất {len(df):,} dòng (Chế độ: {load_mode.upper()}).")
    
    return {
        'df': df,
        'load_mode': load_mode,
        'batch_month': payload.get('batch_month', '2022-01'),
        'target_months': payload.get('target_months', []),
        'file_name': payload['file_name'],
        'rows_read': payload['rows_read'],
        'rows_inserted': len(df),
        'lset': payload['lset'],
        'cet': payload['cet'],
    }
