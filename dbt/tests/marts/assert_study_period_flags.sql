{#
  assert_study_period_flags.sql: Kiểm tra tính đúng đắn của cờ phạm vi nghiên cứu (is_in_study_period).
  Tác giả: Nguyễn Hồng Phúc (Phase 2 - QA & Data Quality)
  Mục tiêu: Đảm bảo các chuyến đón khách trong khoảng [2022-01-01, 2024-01-01) có cờ TRUE,
            các chuyến ngoài khoảng này (nhiễu biên/lỗi đồng hồ) có cờ FALSE.
  Tiêu chuẩn Pass: 0 dòng trả về.
#}

select
    trip_record_key,
    pickup_datetime,
    is_in_study_period
from {{ ref('fact_yellow_taxi_trip') }}
where is_in_study_period <> coalesce(
    pickup_datetime >= timestamp '{{ var("study_start") }}'
    and pickup_datetime <  timestamp '{{ var("study_end") }}',
    false
)
