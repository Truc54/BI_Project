{#
  dim_distance_range.sql: Chiều Phân Dải Cự Ly Di Chuyển (DDS / Marts).
  Quy chuẩn dải cự ly theo Quyết định 4 của Phúc:
    - 1: 0-1 mile (Micro / Very Short Trips)
    - 2: 1-3 miles (Short Trips)
    - 3: 3-5 miles (Medium Trips)
    - 4: 5-10 miles (Long Trips)
    - 5: >10 miles (Very Long / Airport Trips)
    - -1: Invalid/Unknown (Cự ly âm hoặc NULL)
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with range_data as (

    select
        1                               as distance_range_key,
        '0-1 mile'                      as distance_range_name,
        'Cự ly rất ngắn (<= 1 dặm)'     as distance_range_desc,
        cast(0.00 as numeric(12,2))     as min_miles,
        cast(1.00 as numeric(12,2))     as max_miles,
        1                               as sort_order
    union all
    select
        2                               as distance_range_key,
        '1-3 miles'                     as distance_range_name,
        'Cự ly ngắn (1 - 3 dặm)'        as distance_range_desc,
        cast(1.01 as numeric(12,2))     as min_miles,
        cast(3.00 as numeric(12,2))     as max_miles,
        2                               as sort_order
    union all
    select
        3                               as distance_range_key,
        '3-5 miles'                     as distance_range_name,
        'Cự ly trung bình (3 - 5 dặm)'  as distance_range_desc,
        cast(3.01 as numeric(12,2))     as min_miles,
        cast(5.00 as numeric(12,2))     as max_miles,
        3                               as sort_order
    union all
    select
        4                               as distance_range_key,
        '5-10 miles'                    as distance_range_name,
        'Cự ly dài (5 - 10 dặm)'        as distance_range_desc,
        cast(5.01 as numeric(12,2))     as min_miles,
        cast(10.00 as numeric(12,2))    as max_miles,
        4                               as sort_order
    union all
    select
        5                               as distance_range_key,
        '>10 miles'                     as distance_range_name,
        'Cự ly rất dài (> 10 dặm)'      as distance_range_desc,
        cast(10.01 as numeric(12,2))    as min_miles,
        cast(999999.00 as numeric(12,2)) as max_miles,
        5                               as sort_order
    union all
    select
        -1                              as distance_range_key,
        'Invalid/Unknown'               as distance_range_name,
        'Cự ly không hợp lệ hoặc thiếu' as distance_range_desc,
        cast(-1.00 as numeric(12,2))    as min_miles,
        cast(-0.01 as numeric(12,2))    as max_miles,
        99                              as sort_order

)

select * from range_data
order by sort_order
