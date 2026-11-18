{#
  fact_yellow_taxi_trip.sql: Bảng Fact Trung Tâm Cuốc Xe Taxi (DDS / Marts).
  - Hạt dữ liệu (Grain): 1 dòng = 1 dòng bản ghi nguồn (one row per source record).
  - Chiến lược nạp: Incremental load theo unique_key = 'trip_record_key'.
  - Surrogate Key sinh bằng hàm băm MD5 chuẩn trên (source_file_month, source_row_number).
  - 11 Khóa Ngoại (Foreign Keys):
      * pickup_date_key, dropoff_date_key   -> dim_date
      * pickup_time_key, dropoff_time_key   -> dim_time
      * pickup_zone_key, dropoff_zone_key   -> dim_taxi_zone
      * vendor_key                          -> dim_vendor
      * rate_code_key                       -> dim_rate_code
      * payment_type_key                    -> dim_payment_type
      * passenger_group_key                 -> dim_passenger_group
      * distance_range_key                  -> dim_distance_range
#}

{{
    config(
        materialized='incremental',
        unique_key='trip_record_key',
        schema='dds',
        incremental_strategy='delete+insert'
    )
}}

with cleaned_trips as (

    select * from {{ ref('stg_yellow_trips_cleaned') }}
    {% if is_incremental() %}
        -- Lọc các mẻ nạp mới theo source_file_month khi chạy incremental
        where source_file_month >= (select coalesce(max(source_file_month), '1900-01') from {{ this }})
    {% endif %}

),

dim_passenger as (

    select passenger_group_key, passenger_group_name
    from {{ ref('dim_passenger_group') }}

),

dim_distance as (

    select distance_range_key, distance_range_name
    from {{ ref('dim_distance_range') }}

),

staged as (

    select
        -- Khóa chính Surrogate Key duy nhất của bảng Fact
        md5(concat_ws('||', t.source_file_month, cast(t.source_row_number as text))) as trip_record_key,

        -- Thuộc tính kiểm toán / Lineage
        t.source_file_month,
        t.source_row_number,

        -- 11 Khóa Ngoại (Foreign Keys)
        t.pickup_date_key,
        t.dropoff_date_key,
        t.pickup_time_key,
        t.dropoff_time_key,
        t.pu_location_id                                                             as pickup_zone_key,
        t.do_location_id                                                             as dropoff_zone_key,
        t.vendor_id                                                                  as vendor_key,
        t.rate_code_id                                                               as rate_code_key,
        t.payment_type                                                               as payment_type_key,
        coalesce(pg.passenger_group_key, -1)                                         as passenger_group_key,
        coalesce(dr.distance_range_key, -1)                                          as distance_range_key,

        -- Degenerate Attributes / Mốc thời gian gốc
        t.pickup_datetime,
        t.dropoff_datetime,
        t.store_and_fwd_flag,

        -- Độ đo (Measures) & Bộ đếm cơ bản
        cast(1 as smallint)                                                          as trip_record_count,
        t.passenger_count,
        t.trip_distance,
        t.duration_minutes,
        t.speed_mph,

        -- 9 Cấu phần Tiền tệ & Doanh thu (USD)
        t.fare_amount,
        t.extra,
        t.mta_tax,
        t.tip_amount,
        t.tolls_amount,
        t.improvement_surcharge,
        t.congestion_surcharge,
        t.airport_fee,
        t.total_amount,

        -- Cờ nghiệp vụ & Bộ lọc phân tích
        t.is_in_study_period,
        t.is_negative_charge,
        t.is_valid_duration,
        t.is_valid_for_tip_ratio,
        t.is_valid_for_speed

    from cleaned_trips t
    left join dim_passenger pg on pg.passenger_group_name = t.passenger_group_name
    left join dim_distance  dr on dr.distance_range_name  = t.distance_range_name

)

select * from staged
