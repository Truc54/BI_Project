{#
  dim_rate_code.sql: Chiều Loại Biểu Giá Cước Taxi (DDS / Marts).
  - Bảo toàn danh mục biểu phí chuẩn TLC (1..6).
  - Tách riêng RatecodeID = 99 thành member độc lập (Special/Flexible Rate, OD-05, 347.274 dòng).
  - Bản ghi mặc định -1: Missing / Unknown Rate Code (dành cho NULL / mã lỗi khác).
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with rate_data as (

    select
        1                               as rate_code_key,
        1                               as rate_code_id,
        'Standard rate'                 as rate_description,
        'Standard'                      as rate_category,
        false                           as is_flat_fare
    union all
    select
        2                               as rate_code_key,
        2                               as rate_code_id,
        'JFK'                           as rate_description,
        'Airport'                       as rate_category,
        true                            as is_flat_fare
    union all
    select
        3                               as rate_code_key,
        3                               as rate_code_id,
        'Newark'                        as rate_description,
        'Airport'                       as rate_category,
        false                           as is_flat_fare
    union all
    select
        4                               as rate_code_key,
        4                               as rate_code_id,
        'Nassau or Westchester'         as rate_description,
        'Out of Town'                   as rate_category,
        false                           as is_flat_fare
    union all
    select
        5                               as rate_code_key,
        5                               as rate_code_id,
        'Negotiated fare'               as rate_description,
        'Negotiated'                    as rate_category,
        false                           as is_flat_fare
    union all
    select
        6                               as rate_code_key,
        6                               as rate_code_id,
        'Group ride'                    as rate_description,
        'Special'                       as rate_category,
        false                           as is_flat_fare
    union all
    select
        99                              as rate_code_key,
        99                              as rate_code_id,
        'Special / Flexible Rate (99)'  as rate_description,
        'Special'                       as rate_category,
        false                           as is_flat_fare
    union all
    select
        -1                              as rate_code_key,
        -1                              as rate_code_id,
        'Missing / Unknown Rate Code'   as rate_description,
        'Unknown'                       as rate_category,
        false                           as is_flat_fare

)

select * from rate_data
order by rate_code_key
