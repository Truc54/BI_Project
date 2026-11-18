{#
  dim_payment_type.sql: Chiều Phương Thức Thanh Toán (DDS / Marts).
  - Bảo toàn danh mục thanh toán chuẩn TLC (1..6).
  - Bổ sung PaymentTypeID = 0 (OD-03, 2.677.659 dòng, 3,43%, khối thiếu metadata).
  - Cờ allows_electronic_tip = TRUE duy nhất cho Credit Card (1) theo QĐ2 của Phúc.
  - Bản ghi mặc định -1: Missing / Invalid Payment Type.
#}

{{
    config(
        materialized='table',
        schema='dds'
    )
}}

with payment_data as (

    select
        0                               as payment_type_key,
        0                               as payment_type_id,
        'Code 0 (Chưa có từ điển TLC)'  as payment_description,
        'Unknown'                       as payment_group,
        false                           as allows_electronic_tip
    union all
    select
        1                               as payment_type_key,
        1                               as payment_type_id,
        'Credit card'                   as payment_description,
        'Electronic'                    as payment_group,
        true                            as allows_electronic_tip
    union all
    select
        2                               as payment_type_key,
        2                               as payment_type_id,
        'Cash'                          as payment_description,
        'Cash'                          as payment_group,
        false                           as allows_electronic_tip
    union all
    select
        3                               as payment_type_key,
        3                               as payment_type_id,
        'No charge'                     as payment_description,
        'Non-Revenue'                   as payment_group,
        false                           as allows_electronic_tip
    union all
    select
        4                               as payment_type_key,
        4                               as payment_type_id,
        'Dispute'                       as payment_description,
        'Exception'                     as payment_group,
        false                           as allows_electronic_tip
    union all
    select
        5                               as payment_type_key,
        5                               as payment_type_id,
        'Unknown'                       as payment_description,
        'Exception'                     as payment_group,
        false                           as allows_electronic_tip
    union all
    select
        6                               as payment_type_key,
        6                               as payment_type_id,
        'Voided trip'                   as payment_description,
        'Exception'                     as payment_group,
        false                           as allows_electronic_tip
    union all
    select
        -1                              as payment_type_key,
        -1                              as payment_type_id,
        'Missing / Invalid Payment Type' as payment_description,
        'Unknown'                       as payment_group,
        false                           as allows_electronic_tip

)

select * from payment_data
order by payment_type_key
