{#
  dim_time.sql: Chiều Thời Gian Phút Trong Ngày (DDS / Marts).
  Bao gồm đúng 1,440 phút trong ngày (0..1439) tương ứng time_key = hour * 60 + minute.
  Phân nhóm time_of_day_bucket theo chuẩn OD-08:
    - NIGHT: 00:00 - 05:59
    - MORN:  06:00 - 10:59
    - MID:   11:00 - 13:59
    - AFT:   14:00 - 17:59
    - EVE:   18:00 - 23:59
  Bao gồm bản ghi mặc định time_key = -1 cho giá trị NULL / không hợp lệ.
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with time_spine as (

    select
        generate_series(0, 1439) as minute_of_day

),

times as (

    select
        minute_of_day                                                  as time_key,
        cast(minute_of_day / 60 as integer)                            as hour_24,
        cast(minute_of_day % 60 as integer)                            as minute,
        to_char(to_timestamp(minute_of_day * 60), 'HH24:MI')          as time_label_24,
        case
            when minute_of_day / 60 between 0 and 5   then 'NIGHT'
            when minute_of_day / 60 between 6 and 10  then 'MORN'
            when minute_of_day / 60 between 11 and 13 then 'MID'
            when minute_of_day / 60 between 14 and 17 then 'AFT'
            else                                           'EVE'
        end                                                            as time_of_day_bucket
    from time_spine

),

unknown_time as (

    select
        -1                                                             as time_key,
        -1                                                             as hour_24,
        -1                                                             as minute,
        'Unknown'                                                      as time_label_24,
        'UNKNOWN'                                                      as time_of_day_bucket

)

select * from times
union all
select * from unknown_time
order by time_key
