{#
  stg_yellow_trips_cleaned: cuốc xe Yellow Taxi đã làm sạch (tầng clean_view).
  Mức hạt: 1 dòng = 1 dòng của stage.raw_yellow_tripdata (không lọc bỏ dòng nào).
  Quy tắc chi tiết: docs/cleaning_rules.md
#}

{%- set study_start    = var('study_start') -%}
{%- set study_end      = var('study_end') -%}
{%- set date_dim_start = var('date_dim_start') -%}
{%- set date_dim_end   = var('date_dim_end') -%}
{%- set max_speed      = var('max_speed_mph') -%}

with source as (

    select * from {{ source('stage', 'raw_yellow_tripdata') }}

),

valid_zones as (

    select location_id
    from {{ ref('stg_taxi_zones_cleaned') }}
    where not is_unknown_member

),

base as (

    select
        s.source_file_month,
        s.source_row_number,

        s.tpep_pickup_datetime                                       as pickup_datetime,
        s.tpep_dropoff_datetime                                      as dropoff_datetime,
        extract(epoch from (s.tpep_dropoff_datetime - s.tpep_pickup_datetime)) as duration_seconds,

        -- mã nguồn (giữ để truy vết, kể cả mã lạ như VendorID 5/6, payment_type 0)
        s.vendor_id                                                  as vendor_id_source,
        cast(s.rate_code_id as integer)                              as rate_code_id_source,
        cast(s.payment_type as integer)                              as payment_type_source,
        s.pu_location_id                                             as pu_location_id_source,
        s.do_location_id                                             as do_location_id_source,

        pu.location_id                                               as pu_location_id_valid,
        dz.location_id                                               as do_location_id_valid,

        cast(s.passenger_count as integer)                           as passenger_count,
        s.trip_distance,
        upper(trim(s.store_and_fwd_flag))                            as store_and_fwd_flag_raw,

        s.fare_amount,
        s.extra,
        s.mta_tax,
        s.tip_amount,
        s.tolls_amount,
        s.improvement_surcharge,
        s.congestion_surcharge,
        s.airport_fee,
        s.total_amount

    from source s
    left join valid_zones pu on pu.location_id = s.pu_location_id
    left join valid_zones dz on dz.location_id = s.do_location_id

),

final as (

    select
        -- ===== Lineage =====
        source_file_month,
        source_row_number,

        -- ===== Thời gian gốc =====
        pickup_datetime,
        dropoff_datetime,

        -- ===== B1. Khóa ngày (YYYYMMDD) & khóa giờ (phút trong ngày 0..1439) =====
        case
            when pickup_datetime is null
              or cast(pickup_datetime as date) < date '{{ date_dim_start }}'
              or cast(pickup_datetime as date) > date '{{ date_dim_end }}'
            then -1
            else cast(to_char(pickup_datetime, 'YYYYMMDD') as integer)
        end                                                          as pickup_date_key,
        case
            when dropoff_datetime is null
              or cast(dropoff_datetime as date) < date '{{ date_dim_start }}'
              or cast(dropoff_datetime as date) > date '{{ date_dim_end }}'
            then -1
            else cast(to_char(dropoff_datetime, 'YYYYMMDD') as integer)
        end                                                          as dropoff_date_key,
        coalesce(cast(extract(hour from pickup_datetime) * 60
                      + extract(minute from pickup_datetime) as integer), -1)  as pickup_time_key,
        coalesce(cast(extract(hour from dropoff_datetime) * 60
                      + extract(minute from dropoff_datetime) as integer), -1) as dropoff_time_key,

        -- ===== B2. Cờ phạm vi nghiên cứu =====
        coalesce(
            pickup_datetime >= timestamp '{{ study_start }}'
            and pickup_datetime <  timestamp '{{ study_end }}',
            false
        )                                                            as is_in_study_period,

        -- ===== B3. Thời lượng & vận tốc =====
        cast(round(cast(duration_seconds / 60.0 as numeric), 2) as numeric(12, 2)) as duration_minutes,
        case
            when duration_seconds > 0
             and trip_distance >= 0
             and trip_distance / (duration_seconds / 3600.0) <= {{ max_speed }}
            then cast(round(cast(trip_distance / (duration_seconds / 3600.0) as numeric), 2) as numeric(12, 2))
            else null
        end                                                          as speed_mph,
        coalesce(duration_seconds > 0 and duration_seconds <= 86400, false) as is_valid_duration,
        -- Bộ lọc M9 (Phase 1): >= 60 giây, > 0.1 dặm, 1..80 mph
        coalesce(
            duration_seconds >= 60
            and trip_distance > 0.1
            and trip_distance / (duration_seconds / 3600.0) between 1 and 80,
            false
        )                                                            as is_valid_for_speed,

        -- ===== B4. Nhóm khách & dải cự ly =====
        passenger_count,
        case
            when passenger_count is null or passenger_count <= 0 then 'Unknown/Zero'
            when passenger_count = 1                             then '1 passenger'
            when passenger_count between 2 and 4                 then '2-4 passengers'
            else                                                      '5+ passengers'
        end                                                          as passenger_group_name,
        cast(trip_distance as numeric(12, 2))                        as trip_distance,
        case
            when trip_distance is null or trip_distance < 0 then 'Invalid/Unknown'
            when trip_distance <= 1                         then '0-1 mile'
            when trip_distance <= 3                         then '1-3 miles'
            when trip_distance <= 5                         then '3-5 miles'
            when trip_distance <= 10                        then '5-10 miles'
            else                                                 '>10 miles'
        end                                                          as distance_range_name,

        -- ===== B5. Mã chuẩn hóa (NULL / mã lạ -> -1) =====
        case when vendor_id_source in (1, 2) then vendor_id_source else -1 end              as vendor_id,
        case when rate_code_id_source in (1, 2, 3, 4, 5, 6, 99) then rate_code_id_source else -1 end as rate_code_id,
        case when payment_type_source between 1 and 6 then payment_type_source else -1 end as payment_type,
        coalesce(pu_location_id_valid, -1)                                                  as pu_location_id,
        coalesce(do_location_id_valid, -1)                                                  as do_location_id,

        -- mã nguồn để truy vết
        vendor_id_source,
        rate_code_id_source,
        payment_type_source,
        pu_location_id_source,
        do_location_id_source,

        case when store_and_fwd_flag_raw in ('Y', 'N') then store_and_fwd_flag_raw end as store_and_fwd_flag,

        -- ===== B6. Cước phí (giữ nguyên giá trị, kể cả âm) =====
        cast(fare_amount           as numeric(18, 4)) as fare_amount,
        cast(extra                 as numeric(18, 4)) as extra,
        cast(mta_tax               as numeric(18, 4)) as mta_tax,
        cast(tip_amount            as numeric(18, 4)) as tip_amount,
        cast(tolls_amount          as numeric(18, 4)) as tolls_amount,
        cast(improvement_surcharge as numeric(18, 4)) as improvement_surcharge,
        cast(congestion_surcharge  as numeric(18, 4)) as congestion_surcharge,
        cast(airport_fee           as numeric(18, 4)) as airport_fee,
        cast(total_amount          as numeric(18, 4)) as total_amount,

        coalesce(total_amount < 0 or fare_amount < 0, false)         as is_negative_charge,
        coalesce(payment_type_source = 1 and fare_amount > 0, false) as is_valid_for_tip_ratio

    from base

)

select * from final
