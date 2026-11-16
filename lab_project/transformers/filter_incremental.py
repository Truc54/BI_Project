if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer

@transformer
def filter_incremental(window_data, source_data, *args, **kwargs):
    """
    Điều phối và lọc dữ liệu (Data Filtering & Routing):
    - FULL LOAD: Giữ lại toàn bộ dữ liệu 24 tháng để nạp toàn diện.
    - INCREMENTAL LOAD: Lọc chỉ lấy các bản ghi thuộc cửa sổ trích xuất LSET < batch <= CET.
    """
    load_mode = window_data.get('load_mode', 'incremental')
    df = source_data['df']
    target_months = window_data.get('target_months', [])

    if df.empty:
        print("[!] Không có dữ liệu để xử lý trong đợt này.")
        return {'df': df, 'load_mode': load_mode, 'months': []}

    if load_mode == 'full':
        print(f"[*] [FULL LOAD] Tiếp nhận toàn bộ {len(df):,} dòng của {len(source_data.get('months', []))} tháng.")
        filtered_df = df
    else:
        # Lọc theo các tháng được chỉ định trong target_months
        if target_months:
            filtered_df = df[df['source_file_month'].isin(target_months)].copy()
        else:
            filtered_df = df

        print(f"[*] [INCREMENTAL LOAD] Sau khi lọc cửa sổ [{window_data.get('lset')} -> {window_data.get('cet')}]: còn {len(filtered_df):,} dòng.")

    return {
        'df': filtered_df,
        'load_mode': load_mode,
        'lset': window_data.get('lset'),
        'cet': window_data.get('cet'),
        'target_months': target_months,
        'batch_month': target_months[0] if target_months else source_data.get('months', ['2022-01'])[0],
        'file_name': source_data.get('file_name', 'yellow_tripdata.parquet'),
        'rows_read': source_data.get('rows_read', len(filtered_df)),
    }
