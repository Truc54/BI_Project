{#
  assert_duration_and_speed_logic.sql: Kiểm tra tính logic của thời lượng và vận tốc.
  Tác giả: Nguyễn Hồng Phúc (Phase 2 - QA & Data Quality)
  Mục tiêu:
    1. Cuốc xe có thời lượng <= 0 thì vận tốc (speed_mph) bắt buộc phải là NULL.
    2. Vận tốc không được vượt quá ngưỡng tối đa hợp lý (var('max_speed_mph')) và không được âm.
  Tiêu chuẩn Pass: 0 dòng trả về.
#}

select
    trip_record_key,
    duration_minutes,
    speed_mph,
    'speed_not_null_when_duration_nonpositive' as violation_reason
from {{ ref('fact_yellow_taxi_trip') }}
where duration_minutes <= 0
  and speed_mph is not null

union all

select
    trip_record_key,
    duration_minutes,
    speed_mph,
    'speed_out_of_reasonable_bounds' as violation_reason
from {{ ref('fact_yellow_taxi_trip') }}
where speed_mph > {{ var('max_speed_mph') }}
   or speed_mph < 0
