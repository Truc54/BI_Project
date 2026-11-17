{#
  dim_passenger_group.sql: Chiều Phân Nhóm Hành Khách (DDS / Marts).
  Quy chuẩn phân nhóm theo Quyết định 3 của Phúc:
    - 1: Solo Rider (1 passenger)
    - 2: Small Group (2-4 passengers)
    - 3: Large Group (5+ passengers)
    - -1: Unknown/Zero (NULL hoặc <= 0)
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with group_data as (

    select
        1                               as passenger_group_key,
        '1 passenger'                   as passenger_group_name,
        'Solo Rider'                    as passenger_group_desc,
        1                               as min_passengers,
        1                               as max_passengers
    union all
    select
        2                               as passenger_group_key,
        '2-4 passengers'                as passenger_group_name,
        'Small Group'                   as passenger_group_desc,
        2                               as min_passengers,
        4                               as max_passengers
    union all
    select
        3                               as passenger_group_key,
        '5+ passengers'                 as passenger_group_name,
        'Large Group'                   as passenger_group_desc,
        5                               as min_passengers,
        99                              as max_passengers
    union all
    select
        -1                              as passenger_group_key,
        'Unknown/Zero'                  as passenger_group_name,
        'Chưa xác định hoặc số khách 0' as passenger_group_desc,
        -1                              as min_passengers,
        0                               as max_passengers

)

select * from group_data
order by passenger_group_key
