{#
  assert_revenue_components_balance.sql: Kiểm tra tính cân đối của các cấu phần doanh thu.
  Tác giả: Nguyễn Hồng Phúc (Phase 2 - QA & Data Quality)
  Mục tiêu: Theo dõi độ lệch kế toán doanh thu (OD-02):
            total_amount = fare_amount + extra + mta_tax + tip_amount + tolls_amount
                         + improvement_surcharge + congestion_surcharge + airport_fee
  Lưu ý (OD-02): Theo đặc tả Phase 1, dữ liệu TLC nguồn có ~26% bản ghi (đặc biệt Vendor 1)
  có congestion_surcharge/airport_fee gộp trong extra, dẫn đến lệch tổng tiền tự nhiên từ nguồn.
  Cấu hình severity='warn' để ghi nhận nhật ký kiểm toán chất lượng mà không làm gián đoạn pipeline.
#}

{{ config(severity = 'warn') }}

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
