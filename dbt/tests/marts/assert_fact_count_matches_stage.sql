{#
  assert_fact_count_matches_stage.sql: Kiểm tra đối soát số dòng giữa Stage và Fact.
  Tác giả: Nguyễn Hồng Phúc (Phase 2 - QA & Data Quality)
  Mục tiêu: Đảm bảo số dòng trong stage.raw_yellow_tripdata khớp 100% với dds.fact_yellow_taxi_trip
            theo từng mẻ tháng nguồn (source_file_month). Tuyệt đối không thất thoát dữ liệu.
  Tiêu chuẩn Pass: Không có dòng nào trả về (0 rows returned).
#}

with stage_counts as (

    select
        source_file_month,
        count(*) as stage_rows
    from {{ source('stage', 'raw_yellow_tripdata') }}
    group by 1

),

fact_counts as (

    select
        source_file_month,
        count(*) as fact_rows
    from {{ ref('fact_yellow_taxi_trip') }}
    group by 1

)

select
    coalesce(s.source_file_month, f.source_file_month) as source_file_month,
    s.stage_rows,
    f.fact_rows,
    abs(coalesce(s.stage_rows, 0) - coalesce(f.fact_rows, 0)) as diff_rows
from stage_counts s
full outer join fact_counts f using (source_file_month)
where s.stage_rows is distinct from f.fact_rows
