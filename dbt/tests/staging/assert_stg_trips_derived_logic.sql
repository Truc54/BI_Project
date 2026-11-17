-- Kiểm tra tính đúng của các trường dẫn xuất. Mỗi dòng trả về là một vi phạm.
select source_file_month, source_row_number, 'speed_not_null_when_duration_nonpositive' as rule
from {{ ref('stg_yellow_trips_cleaned') }}
where duration_minutes <= 0 and speed_mph is not null

union all
select source_file_month, source_row_number, 'speed_above_max'
from {{ ref('stg_yellow_trips_cleaned') }}
where speed_mph > {{ var('max_speed_mph') }} or speed_mph < 0

union all
select source_file_month, source_row_number, 'time_key_out_of_range'
from {{ ref('stg_yellow_trips_cleaned') }}
where pickup_time_key not between 0 and 1439
   or dropoff_time_key not between 0 and 1439

union all
select source_file_month, source_row_number, 'date_key_mismatch'
from {{ ref('stg_yellow_trips_cleaned') }}
where pickup_date_key <> -1
  and pickup_date_key <> cast(to_char(pickup_datetime, 'YYYYMMDD') as integer)

union all
select source_file_month, source_row_number, 'study_flag_mismatch'
from {{ ref('stg_yellow_trips_cleaned') }}
where is_in_study_period <> (
        pickup_datetime >= timestamp '{{ var("study_start") }}'
    and pickup_datetime <  timestamp '{{ var("study_end") }}')

union all
select source_file_month, source_row_number, 'negative_flag_mismatch'
from {{ ref('stg_yellow_trips_cleaned') }}
where is_negative_charge <> coalesce(total_amount < 0 or fare_amount < 0, false)
