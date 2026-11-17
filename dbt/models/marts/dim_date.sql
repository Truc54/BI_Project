{#
  dim_date.sql: Chiều Ngày Lịch (DDS / Marts).
  Bao quát chuỗi ngày từ var('date_dim_start') đến var('date_dim_end').
  Bao gồm bản ghi mặc định date_key = -1 cho trường hợp NULL / ngày ngoài miền.
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with date_spine as (

    select
        cast(generate_series(
            date '{{ var("date_dim_start") }}',
            date '{{ var("date_dim_end") }}',
            interval '1 day'
        ) as date) as full_date

),

dates as (

    select
        cast(to_char(full_date, 'YYYYMMDD') as integer) as date_key,
        full_date,
        cast(extract(year from full_date) as integer)    as year,
        cast(extract(quarter from full_date) as integer) as quarter,
        cast(extract(month from full_date) as integer)   as month,
        to_char(full_date, 'Month')                      as month_name,
        cast(extract(day from full_date) as integer)     as day,
        cast(extract(isodow from full_date) as integer)  as day_of_week,
        to_char(full_date, 'Day')                        as day_name,
        case
            when extract(isodow from full_date) in (6, 7) then true
            else false
        end                                              as is_weekend,
        case
            when full_date >= date '{{ var("study_start") }}'
             and full_date <  date '{{ var("study_end") }}'
            then true
            else false
        end                                              as is_in_study_period
    from date_spine

),

unknown_date as (

    select
        -1                                               as date_key,
        cast('1900-01-01' as date)                       as full_date,
        1900                                             as year,
        1                                                as quarter,
        1                                                as month,
        'Unknown'                                        as month_name,
        1                                                as day,
        -1                                               as day_of_week,
        'Unknown'                                        as day_name,
        false                                            as is_weekend,
        false                                            as is_in_study_period

)

select * from dates
union all
select * from unknown_date
order by date_key
