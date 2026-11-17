-- Khóa nguồn (source_file_month, source_row_number) phải duy nhất trong clean_view.
select source_file_month, source_row_number, count(*) as n
from {{ ref('stg_yellow_trips_cleaned') }}
group by 1, 2
having count(*) > 1
