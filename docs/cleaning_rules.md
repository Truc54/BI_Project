# Quy tắc Làm sạch tầng `clean_view` (Phase 2)

**Phụ trách:** Lê Văn Lộc
**Đầu vào:** `stage.raw_yellow_tripdata`, `stage.raw_taxi_zones` (pipeline Mage của Trực)
**Đầu ra:** 2 view trong schema `clean_view`: `stg_yellow_trips_cleaned`, `stg_taxi_zones_cleaned`
**Mã nguồn:** [dbt/models/staging/](../dbt/models/staging/)

---

## 1. Nguyên tắc chung

1. **Không loại bỏ dòng nào.** `stg_yellow_trips_cleaned` có đúng 1 dòng cho mỗi dòng stage, khóa `(source_file_month, source_row_number)`. Dị thường được **gắn cờ** chứ không bị xóa, để đối soát số dòng Source = Stage = Fact (Phúc) luôn khớp.
2. **Giữ giá trị gốc.** Timestamp, cự ly, các khoản tiền (kể cả âm, kể cả ngoại lai) giữ nguyên. Các mã danh mục có thêm cột `*_source` lưu mã gốc.
3. **Mọi khóa danh mục đều NOT NULL.** NULL hoặc mã ngoài miền được đổi thành `-1` (Unknown), nên Dũng join được 100% sang Dimension.
4. Các ngưỡng nằm trong `vars` của [dbt_project.yml](../dbt/dbt_project.yml), đổi được mà không phải sửa SQL.

| Var | Giá trị | Ý nghĩa |
|---|---|---|
| `study_start`, `study_end` | `2022-01-01`, `2024-01-01` | Kỳ nghiên cứu `[start, end)` |
| `date_dim_start`, `date_dim_end` | `2022-01-01`, `2024-12-31` | Miền của `dim_date` (Dũng) |
| `max_speed_mph` | `120` | Vận tốc tối đa hợp lý |

---

## 2. `stg_yellow_trips_cleaned`

### 2.1 Khóa ngày & giờ

| Cột | Quy tắc |
|---|---|
| `pickup_date_key`, `dropoff_date_key` | `YYYYMMDD` (INT). Ngày nằm ngoài `[date_dim_start, date_dim_end]` hoặc NULL → `-1` |
| `pickup_time_key`, `dropoff_time_key` | Số phút trong ngày `giờ*60 + phút`, miền `0..1439`, khớp `dim_time` 1.440 dòng của Dũng |

> Lệch so với đặc tả Phase 1: `dds_physical_spec.md` dùng TimeKey dạng `HHMM` (0–2359) và DimDate 2021–2024. Ở đây làm theo plan Phase 2 (phút 0–1439, dim_date 2022–2024). Nếu nhóm đổi lại thì chỉ cần sửa biểu thức / var.

### 2.2 Cờ kỳ nghiên cứu
`is_in_study_period = pickup_datetime ∈ [2022-01-01, 2024-01-01)`; NULL → `FALSE`.

### 2.3 Thời lượng & vận tốc

| Cột | Quy tắc |
|---|---|
| `duration_minutes` | `(dropoff − pickup)` tính bằng phút, làm tròn 2 chữ số, **có dấu** (giữ giá trị âm/0) |
| `speed_mph` | `trip_distance / (duration giờ)`. **NULL** khi duration ≤ 0, cự ly NULL/âm, hoặc vận tốc > 120 mph |
| `is_valid_duration` | `0 < duration ≤ 24 giờ` (M7) |
| `is_valid_for_speed` | Bộ lọc M9: duration ≥ 60 giây, cự ly > 0,1 dặm, vận tốc 1–80 mph. Dùng cho phân tích vận tốc E1 |

### 2.4 Nhóm khách & dải cự ly

| `passenger_group_name` | Điều kiện |
|---|---|
| `1 passenger` | = 1 |
| `2-4 passengers` | 2–4 |
| `5+ passengers` | ≥ 5 |
| `Unknown/Zero` | NULL hoặc ≤ 0 |

| `distance_range_name` | Điều kiện (dặm) |
|---|---|
| `0-1 mile` | 0 ≤ d ≤ 1 |
| `1-3 miles` | 1 < d ≤ 3 |
| `3-5 miles` | 3 < d ≤ 5 |
| `5-10 miles` | 5 < d ≤ 10 |
| `>10 miles` | d > 10 (kể cả ngoại lai > 100 dặm) |
| `Invalid/Unknown` | NULL hoặc d < 0 |

### 2.5 Mã không xác định (fallback −1)

| Cột chuẩn hóa | Miền hợp lệ | Ngoài miền / NULL | Cột mã gốc |
|---|---|---|---|
| `vendor_id` | 1, 2 | −1 (gồm VendorID 5, 6) | `vendor_id_source` |
| `rate_code_id` | 1–6, 99 | −1 | `rate_code_id_source` |
| `payment_type` | 1–6 | −1 (gồm mã 0) | `payment_type_source` |
| `pu_location_id`, `do_location_id` | ID có trong `stg_taxi_zones_cleaned` (1–265) | −1 | `*_location_id_source` |

> **Cần nhóm chốt:** Phase 1 (OD-03, OD-04, `dds_physical_spec.md`) đề xuất giữ VendorID 5/6 và payment_type 0 thành thành viên riêng. Plan Phase 2 của Dũng chỉ có vendor 1/2 và payment 1–6, nên ở đây các mã đó được đổi về −1. Mã gốc vẫn còn trong `*_source`. Muốn tách riêng thì chỉ cần mở rộng danh sách miền hợp lệ trong model và thêm thành viên vào Dimension.
>
> Quy mô trên mẫu 2022-01 + 2023-02: payment_type 0 → −1 là 148.320 / 5.377.886 dòng (2,8%); VendorID 5/6 → −1 là 6.800 dòng.

`store_and_fwd_flag`: chuẩn hóa `trim/upper`; chỉ giữ `Y`/`N`, còn lại là NULL (không ghi nhận).

### 2.6 Cước phí

- 9 cột tiền (`fare_amount`, `extra`, `mta_tax`, `tip_amount`, `tolls_amount`, `improvement_surcharge`, `congestion_surcharge`, `airport_fee`, `total_amount`) giữ nguyên giá trị, ép kiểu `NUMERIC(18,4)`. `congestion_surcharge`/`airport_fee` NULL vẫn để NULL (không ghi nhận, không đổi thành 0).
- `is_negative_charge = total_amount < 0 OR fare_amount < 0`. Đây là ứng viên hoàn tiền / tranh chấp / đảo bút toán; cờ chỉ phân loại theo dấu.
- `is_valid_for_tip_ratio = payment_type_source = 1 AND fare_amount > 0` (Quyết định 2).

---

## 3. `stg_taxi_zones_cleaned`

1. Tên quận chuẩn hóa: `Manhattan`, `Queens`, `Brooklyn`, `Bronx`, `Staten Island`, `EWR`.
2. Giữ nhãn nguồn cho 2 mã hợp lệ không có hình học: **264** = (`Unknown`, `N/A`, `N/A`), **265** = (`N/A`, `Outside of NYC`, `N/A`). Lưu ý: pandas đọc chuỗi `"N/A"` thành NaN nên stage lưu NULL; model khôi phục lại `N/A`.
3. Thêm thành viên **−1** = (`Unknown`, `Unknown Zone`, `N/A`), `is_unknown_member = TRUE`. Thành viên này tách biệt với ID 264.
4. `has_geometry = TRUE` cho ID 1–263.

Kết quả: 266 dòng (265 + 1).

---

## 4. Vận hành & kiểm thử

```bash
# Trong container Mage (dùng POSTGRES_HOST/PORT từ .env)
docker compose exec mage bash -c "cd dbt && dbt run --select staging --profiles-dir . && dbt test --select staging --profiles-dir ."

# Từ máy host (Postgres ở localhost:5433)
cd dbt && dbt run --select staging --profiles-dir . && dbt test --select staging --profiles-dir .
```

Test (41): not_null / unique / accepted_values / relationships trong [schema.yml](../dbt/models/staging/schema.yml), cộng 3 singular test trong [dbt/tests/staging/](../dbt/tests/staging/):
- `assert_stg_trips_row_count_matches_stage`: số dòng từng tháng clean = stage.
- `assert_stg_trips_unique_source_row`: khóa nguồn duy nhất.
- `assert_stg_trips_derived_logic`: speed NULL khi duration ≤ 0, speed ≤ 120, time key trong 0–1439, date key khớp timestamp, cờ kỳ nghiên cứu và cờ âm khớp quy tắc.

### Kết quả chạy thử (2026-11-17, mẫu 2 tháng 2022-01 + 2023-02 = 5.377.886 dòng)

- `dbt run --select staging`: PASS 2/2 view.
- `dbt test --select staging`: PASS 41/41.

| Tháng | Dòng | vendor −1 | payment −1 | rate −1 | PU −1 | Ngoài kỳ | Cước âm |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2022-01 | 2.463.931 | 5.599 | 71.503 | 71.503 | 0 | 38 | 12.937 |
| 2023-02 | 2.913.955 | 1.201 | 76.817 | 76.817 | 0 | 5 | 24.905 |

Kết quả khớp profile Phase 1: không có location ID ngoài 1–265; VendorID 5/6 đều thuộc khối payment_type 0; một số pickup năm 2008/2009 nhận `is_in_study_period = FALSE` và `pickup_date_key = −1`.
