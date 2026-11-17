{#
  assert_revenue_components_balance.sql: Kiểm tra tính cân đối của các cấu phần doanh thu.
  Tác giả: Nguyễn Hồng Phúc (Phase 2 - QA & Data Quality)
  Mục tiêu: Xác nhận phương trình kế toán doanh thu:
            total_amount = fare_amount + extra + mta_tax + tip_amount + tolls_amount
                         + improvement_surcharge + congestion_surcharge + airport_fee
  Dung sai: Cho phép sai lệch số học không quá 0.01 USD do làm tròn số học từ tệp Parquet.
  Tiêu chuẩn Pass: Không có bản ghi nào bị lệch vượt quá 0.01 USD (0 rows returned).
#}

select
    trip_record_key,
    source_file_month,
    source_row_number,
    total_amount,
    (
        coalesce(fare_amount, 0)
        + coalesce(extra, 0)
        + coalesce(mta_tax, 0)
        + coalesce(tip_amount, 0)
        + coalesce(tolls_amount, 0)
        + coalesce(improvement_surcharge, 0)
        + coalesce(congestion_surcharge, 0)
        + coalesce(airport_fee, 0)
    ) as calculated_total,
    abs(
        total_amount - (
            coalesce(fare_amount, 0)
            + coalesce(extra, 0)
            + coalesce(mta_tax, 0)
            + coalesce(tip_amount, 0)
            + coalesce(tolls_amount, 0)
            + coalesce(improvement_surcharge, 0)
            + coalesce(congestion_surcharge, 0)
            + coalesce(airport_fee, 0)
        )
    ) as diff_amount
from {{ ref('fact_yellow_taxi_trip') }}
where abs(
    total_amount - (
        coalesce(fare_amount, 0)
        + coalesce(extra, 0)
        + coalesce(mta_tax, 0)
        + coalesce(tip_amount, 0)
        + coalesce(tolls_amount, 0)
        + coalesce(improvement_surcharge, 0)
        + coalesce(congestion_surcharge, 0)
        + coalesce(airport_fee, 0)
    )
) > 0.01
