{#
  dim_taxi_zone.sql: Chiều Vùng Taxi Không Gian / Địa Lý (DDS / Marts).
  Nguồn dữ liệu: stg_taxi_zones_cleaned.
  - zone_key: surrogate key tương ứng location_id (trừ bản ghi -1).
  - Bảo toàn 265 LocationID chuẩn TLC.
  - Bảo toàn nguyên vẹn 2 mã hợp lệ không có hình học:
      * ID 264 = (Unknown, NV/N/A, N/A, has_geometry = false)
      * ID 265 = (N/A, Outside of NYC, N/A, has_geometry = false)
  - Bản ghi mặc định -1: Borough = 'Thiếu mã vùng (Missing)', Zone = 'Unknown Zone'.
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with cleaned as (

    select * from {{ ref('stg_taxi_zones_cleaned') }}

),

final as (

    select
        location_id                                      as zone_key,
        location_id,
        borough,
        zone_name,
        service_zone,
        has_geometry,
        is_unknown_member
    from cleaned

)

select * from final
order by zone_key
