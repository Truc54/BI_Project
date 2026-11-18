{#
  dim_vendor.sql: Chiều Nhà Cung Cấp Thiết Bị Công Nghệ TPEP (DDS / Marts).
  - Bảo toàn mã gốc VendorID:
      * 1: Creative Mobile Technologies, LLC (CMT)
      * 2: VeriFone Inc. (VeriFone / Curb / VTS)
      * 5: Unknown Vendor (Code 5) (OD-04, 143 dòng)
      * 6: Unknown Vendor (Code 6) (OD-04, 68.269 dòng)
      * -1: Missing / Unknown Vendor
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with vendor_data as (

    select
        1                                                    as vendor_key,
        1                                                    as vendor_id,
        'Creative Mobile Technologies, LLC'                  as vendor_name,
        'CMT'                                                as vendor_short_name
    union all
    select
        2                                                    as vendor_key,
        2                                                    as vendor_id,
        'VeriFone Inc.'                                      as vendor_name,
        'VeriFone / Curb / VTS'                              as vendor_short_name
    union all
    select
        5                                                    as vendor_key,
        5                                                    as vendor_id,
        'Unknown Vendor (Code 5)'                            as vendor_name,
        'Code 5'                                             as vendor_short_name
    union all
    select
        6                                                    as vendor_key,
        6                                                    as vendor_id,
        'Unknown Vendor (Code 6)'                            as vendor_name,
        'Code 6'                                             as vendor_short_name
    union all
    select
        -1                                                   as vendor_key,
        -1                                                   as vendor_id,
        'Missing / Unknown Vendor'                           as vendor_name,
        'Unknown'                                            as vendor_short_name

)

select * from vendor_data
order by vendor_key
