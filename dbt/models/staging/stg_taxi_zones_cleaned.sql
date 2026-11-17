{#
  stg_taxi_zones_cleaned: danh mục Taxi Zone đã chuẩn hóa (tầng clean_view).
  - Chuẩn hóa tên 6 quận chính (Manhattan, Queens, Brooklyn, Bronx, Staten Island, EWR).
  - Giữ nguyên nhãn nguồn của 2 mã hợp lệ không có hình học:
      264 = (Unknown, N/A, N/A); 265 = (N/A, Outside of NYC, N/A).
    Lưu ý: pandas đọc chuỗi "N/A" thành NaN nên stage lưu NULL -> khôi phục lại "N/A".
  - Thêm thành viên mặc định location_id = -1 (Unknown Zone) cho mã thiếu/không hợp lệ.
#}

with source as (

    select * from {{ source('stage', 'raw_taxi_zones') }}

),

cleaned as (

    select
        cast(location_id as integer)                            as location_id,
        case lower(trim(borough))
            when 'manhattan'     then 'Manhattan'
            when 'queens'        then 'Queens'
            when 'brooklyn'      then 'Brooklyn'
            when 'bronx'         then 'Bronx'
            when 'the bronx'     then 'Bronx'
            when 'staten island' then 'Staten Island'
            when 'ewr'           then 'EWR'
            when 'unknown'       then 'Unknown'
            else coalesce(nullif(trim(borough), ''), 'N/A')
        end                                                     as borough,
        coalesce(nullif(trim(zone), ''), 'N/A')                 as zone_name,
        coalesce(nullif(trim(service_zone), ''), 'N/A')         as service_zone,
        (location_id between 1 and 263)                         as has_geometry,
        false                                                   as is_unknown_member
    from source
    where location_id is not null

),

unknown_member as (

    select
        -1               as location_id,
        'Unknown'        as borough,
        'Unknown Zone'   as zone_name,
        'N/A'            as service_zone,
        false            as has_geometry,
        true             as is_unknown_member

)

select * from cleaned
union all
select * from unknown_member
