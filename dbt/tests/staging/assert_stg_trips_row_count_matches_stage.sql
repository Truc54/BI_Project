-- clean_view không được làm mất hoặc nhân bản dòng: số dòng theo từng tháng tệp phải khớp stage.
with stage_counts as (
    select source_file_month, count(*) as n
    from {{ source('stage', 'raw_yellow_tripdata') }}
    group by 1
),
clean_counts as (
    select source_file_month, count(*) as n
    from {{ ref('stg_yellow_trips_cleaned') }}
    group by 1
)
select
    coalesce(s.source_file_month, c.source_file_month) as source_file_month,
    s.n as stage_rows,
    c.n as clean_rows
from stage_counts s
full outer join clean_counts c using (source_file_month)
where s.n is distinct from c.n
