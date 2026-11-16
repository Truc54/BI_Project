# Selected Data Profile: Observed Measurements (Phase 1)

**Tác giả:** Lộc (đồng chủ trì profile cùng Dũng; phần đo trên dữ liệu thật và hệ quả mô hình)
**Bổ sung cho:** [selected_data_profile.md (Dũng)](../dung/selected_data_profile.md). Hai bản cần được hợp nhất (§9)
**Bằng chứng:** [profile_selected_data.py](profile_selected_data.py) (DuckDB 1.4.5) → [profile_results.json](profile_results.json). Tên khóa JSON ghi trong ngoặc vuông
**Dữ liệu:** 24 tệp `yellow_tripdata_2022-01` … `2023-12`; tổng 1.250.843.281 byte, khớp số byte trong overview [`_meta`]

> **Nhãn của mỗi phát hiện:** [Đo] = đo trên 24 tệp; [TLC] = theo tài liệu TLC; [Suy luận] = giải thích phù hợp với số đo nhưng chưa được xác nhận; [Mở] = chưa kết luận được.
>
> **Tập tính (population), ghi ở đầu mỗi bảng:**
>
> | Tên | Định nghĩa | Số dòng |
> |:---|:---|---:|
> | `ALL_ROWS` | Toàn bộ dòng của 24 tệp | 77.966.324 |
> | `STUDY` | Dòng có pickup trong [2022-01-01, 2024-01-01) | 77.965.701 |
> | `PAYMENT_NZ` | `ALL_ROWS` có `payment_type ≠ 0` | 75.288.665 |
>
> Thống kê "theo tháng tệp" nhóm theo tên tệp; thống kê "theo năm/tháng pickup" nhóm theo timestamp đón.
>
> **Tái lập:** tải 24 tệp vào `dataset/trip_data/` (xem README), `pip install duckdb`, rồi chạy `python deliverables/phase1/loc/profile_selected_data.py`. Các tổng tiền có thể chênh ở chữ số thập phân thứ 4–5 giữa các lần chạy do DuckDB cộng song song số thực; các số đếm thì không đổi.
>
> Kết quả chỉ mô tả 2022–2023, không suy rộng cho 2009–2026 của đề bài.

---

## 1. Schema thực tế [Đo]

Cả 24 tệp đều có đúng 19 cột, nhưng **schema đổi từ tệp 2023-02** [`_meta.files[].schema`]:

| Cột | 2022-01 … 2023-01 | 2023-02 … 2023-12 | Hệ quả |
|:---|:---|:---|:---|
| `airport_fee` | `airport_fee` | **`Airport_fee`** | Cùng một trường logic; khi đọc phải gộp theo tên không phân biệt hoa thường (script dùng `union_by_name`) |
| `passenger_count` | DOUBLE | INT64 | Mô hình dùng số nguyên |
| `RatecodeID` | DOUBLE | INT64 | Mô hình dùng số nguyên |
| `VendorID`, `PULocationID`, `DOLocationID` | INT64 | INT32 | Không ảnh hưởng |
| `tpep_*_datetime` | TIMESTAMP | TIMESTAMP | Giờ địa phương NYC, không kèm múi giờ |

Không có cột định danh chuyến đi.

## 2. Khối lượng và bao phủ [Đo]

| Chỉ tiêu | Tập tính | Giá trị |
|:---|:---|---:|
| Tổng bản ghi | `ALL_ROWS` | **77.966.324** |
| Bản ghi theo tệp năm 2022 / 2023 | `ALL_ROWS`, theo tháng tệp | 39.656.098 / 38.310.226 |
| Bản ghi theo năm pickup 2022 / 2023 | `ALL_ROWS`, theo năm pickup | 39.655.573 / 38.310.128 |
| Tháng tệp ít nhất / nhiều nhất | `ALL_ROWS` | 2022-01: 2.463.931 / 2022-10: 3.675.411 |
| Pickup khác tháng của tệp | `ALL_ROWS` | 2.194 (0,003%) |
| Pickup ngoài 2022–2023 | `ALL_ROWS` | 623, gồm năm 2001–2014: 593; năm 2021: 24; năm 2024: 6 |
| Drop-off ngoài 2021–2024 | `ALL_ROWS` | 455 (sớm nhất 1970-01-20) [`date_range_vs_dimdate`] |

Đủ 24/24 tháng. Số dòng từng tháng nằm trong [`monthly`].

## 3. Giá trị thiếu [Đo] (`ALL_ROWS`)

| Trường | NULL | Ghi chú |
|:---|---:|:---|
| `passenger_count`, `RatecodeID`, `store_and_fwd_flag`, `congestion_surcharge`, `airport_fee` | **2.677.659 (3,43%)** mỗi cột | **Cùng một tập dòng**, và tập này trùng đúng tập `payment_type = 0` (cả hai cùng đếm 2.677.659) [`null_cooccurrence`] |
| `VendorID`, timestamps, `PULocationID`, `DOLocationID`, `payment_type`, các cột tiền khác | 0 | |

- Khối 3,43% xuất hiện ở **mọi** tháng tệp: thấp nhất 2,3% (2023-01), cao nhất 5,3% (2023-12).
- [Suy luận] Đây là một loại bản ghi có nguồn gốc riêng, không phải lỗi rời rạc. Các cuốc trong khối vẫn có cự ly, tiền cước và tổng tiền hợp lý: median `total_amount` 19,66 USD (VendorID 1) và 25,29 USD (VendorID 2) [`payment0_by_vendor`]. Nguồn gốc cụ thể chưa được TLC xác nhận [Mở].

## 4. Miền mã [Đo] (`STUDY`, theo năm pickup)

| Trường | Giá trị quan sát (số dòng) | So với từ điển Dũng dùng |
|:---|:---|:---|
| `VendorID` | 2: 56.588.514 · 1: 21.308.775 · **6: 68.269** · **5: 143** | 5 và 6 **không có** trong từ điển. Mọi bản ghi của 5 và 6 đều thuộc khối `payment_type = 0` [`vendor_5_6_span`] |
| `RatecodeID` | 1: 71.069.386 · 2: 2.975.005 · 5: 530.146 · **99: 347.274** · 3: 236.652 · 4: 129.165 · 6: 414 · NULL: 2.677.659 | 99 xuất hiện thật (0,45%) và tách biệt với NULL |
| `payment_type` | 1: 59.942.455 · 2: 14.168.028 · **0: 2.677.659** · 4: 742.368 · 3: 435.183 · 5: 8 · **6: 0** | Mã 0 không có trong từ điển 1–6; mã 6 (Voided) **không xuất hiện** |
| `store_and_fwd_flag` | N · Y · NULL | |
| `passenger_count` | 0 … 9 và NULL | Không có giá trị > 9 |

Không gian, tập `ALL_ROWS` [`location_ids`]: `PULocationID` và `DOLocationID` chỉ nhận giá trị 1 … 265, với 263 ID pickup và 262 ID drop-off khác nhau. **Không có ID ngoài 1–265 và không có NULL.**

## 5. Phân phối và giá trị bất thường [Đo] (`ALL_ROWS`)

| Chỉ tiêu | Số dòng | Tỷ lệ |
|:---|---:|---:|
| `passenger_count = 0` | 1.346.349 | 1,73% |
| `passenger_count` 1 / 2–4 / 5–9 | 56.084.878 / 15.911.074 / 1.946.364 | 71,9% / 20,4% / 2,5% |
| `trip_distance = 0` | 1.347.516 | 1,73% |
| `trip_distance > 100` (max 389.678,46) | 2.833 | 0,004% |
| `fare_amount < 0` | 634.550 | 0,81% |
| `total_amount < 0` | 632.589 | 0,81% |
| …trong đó `payment_type` 4 / 2 / 3 / 0 / 1 | 367.932 / 147.410 / 115.847 / 888 / 512 | |
| Tổng `total_amount` âm | −14,4 triệu USD | 0,74% của tổng 1.949,8 triệu USD |
| Drop-off < pickup | 16.088 | 0,02% |
| Drop-off = pickup | 31.516 | 0,04% |
| Thời lượng > 3 giờ (= > 180 phút) / > 24 giờ | 84.794 / 558 | 0,11% / 0,0007% |
| Thời lượng hợp lệ theo M7 (0 < d ≤ 24 giờ) | 77.918.162 | 99,94% |
| Đạt lọc cơ bản của M9 (≥ 60 s, > 0,1 dặm) | 76.165.377 | 97,7% |
| …trong đó tốc độ > 80 / > 100 / < 1 mph | 6.793 / 5.736 / 97.880 | |
| Hợp lệ đầy đủ theo M9 (thêm 1–80 mph) | 76.060.704 | 97,6% |

Nguồn: [`monthly`], [`passenger_groups`], [`distance_bands`], [`negative_total_by_payment`], [`duration_speed_filters`]. Các số đếm về cự ly 0, cước âm và thời lượng âm/bằng 0 là **tổng của 24 dòng** trong [`monthly`].

## 6. Trùng lặp và dòng có tổng tiền âm [Đo] (`ALL_ROWS`)

| Kiểm tra | Kết quả | Nhận định |
|:---|:---|:---|
| Trùng hoàn toàn trên 19 cột | 3 nhóm, thừa 3 dòng | [Đo] Không đáng kể; không có căn cứ loại bỏ |
| Nhóm ứng viên trùng (cùng VendorID, pickup, drop-off, PU, DO) | 558.324 nhóm, 1.116.663 dòng | |
| …nhóm đúng 1 dòng `total < 0` và 1 dòng `total > 0` (**ứng viên cặp đảo bút toán**) | 558.184 | |
| …trong đó tổng hai dòng bằng 0 (đối xứng chính xác, sai số ≤ 0,011) | 549.801 (98,5% số ứng viên) | [Suy luận] Mẫu này phù hợp với bút toán đảo (void/hoàn tiền). Nguồn không có cột đánh dấu, nên đây không phải định danh chính thức |
| Dòng âm có ít nhất một dòng dương cùng khóa ứng viên | 558.199 / 632.589 (88,2%) | 74.390 dòng âm **không** có dòng dương tương ứng; không thể coi mọi dòng âm là bút toán đảo |

→ Đây là căn cứ cho cờ `IsNegativeTotalAmount`, một quy tắc nhận diện theo dấu, và cho các phương án Trip Count ở OD-01 [`exact_duplicates`, `candidate_duplicates`, `negative_with_original`].

## 7. Tiền: đối soát `total_amount` (`PAYMENT_NZ`)

- [Đo] `total_amount` khác tổng 8 cột thành phần (sai số 0,011 USD) ở 19.567.921 / 75.288.665 dòng (26,0%) [`total_gap_by_vendor`]:
  - **VendorID 1:** 19.405.822 / 20.511.594 dòng lệch (94,6%). Trong đó 18.029.769 dòng lệch đúng bằng `−congestion_surcharge`; 623.467 dòng bằng `−airport_fee`; 743.312 dòng bằng `−(congestion_surcharge + airport_fee)`. Ba trường hợp này cộng lại giải thích 99,95% số dòng lệch.
  - **VendorID 2:** 162.099 / 54.777.071 dòng lệch (0,3%).
- [Suy luận] Số liệu **phù hợp với giả thuyết** rằng thiết bị của VendorID 1 ghi phụ phí ùn tắc và phí sân bay **cả trong `extra`** lẫn trong cột riêng. Nhóm chưa có tài liệu TLC xác nhận [Mở].
- [Mô hình] Total Revenue = `SUM(total_amount)`. Phân rã cấu phần dùng phần dư `ExtraResidualAmount` là đề xuất đang chờ Phúc (OD-02); xem [Fact logic §6](fact_yellow_taxi_trip_logical.md#6-ghi-chú-về-các-khoản-tiền).

**Mức phí thay đổi trong kỳ** [Đo] (`STUDY`, theo tháng pickup) [`fee_levels_by_pickup_month`, `fee_first_seen`]:

| Khoản | Trước | Sau | Thời điểm chuyển |
|:---|:---|:---|:---|
| `improvement_surcharge` | 0,30 | 1,00 | Tháng 12/2022 có 1.151.837 / 3.399.585 dòng đã là 1,00 (dòng sớm nhất 2022-12-01 14:35:12); tháng 01/2023 có 3.035.348 / 3.066.731 dòng là 1,00 |
| `airport_fee` | 1,25 | 1,75 | Dòng 1,75 đầu tiên 2023-04-04 23:54:40; tháng 04/2023 còn 36.327 dòng 1,25 và có 235.044 dòng 1,75 |
| `congestion_surcharge` | 2,50 | 2,50 | Không đổi |
| `mta_tax` | 0,50 | 0,50 | Không đổi (giá trị phổ biến) |

[Mở] Thay đổi `improvement_surcharge` có thể đi cùng một điều chỉnh biểu cước đồng hồ của TLC cùng thời điểm. Nhóm cần tra thông báo chính thức của TLC trước khi dùng điều này để giải thích E3. Mô hình đã hỗ trợ kiểm tra qua `FareAmount` / Trip Count theo tháng.

**Tiền tip** [Đo] (`ALL_ROWS`) [`tip_by_payment`]:
- Dòng thanh toán thẻ có `tip_amount > 0`: 57.324.815 / 59.942.695 (95,6%).
- Dòng tiền mặt có `tip_amount > 0`: chỉ 3.533 / 14.168.398.

Kết quả này phù hợp với quy tắc tip ratio chỉ tính trên `payment_type = 1` (QĐ2 của Phúc).

## 8. Không gian [Đo] (`ALL_ROWS`) [`borough_share`]

| Borough (giá trị gốc trong lookup) | % pickup | % drop-off |
|:---|---:|---:|
| Manhattan | 88,61% | 88,25% |
| Queens | 9,25% | 5,61% |
| Brooklyn | 0,73% | 3,93% |
| Bronx | 0,15% | 0,62% |
| EWR | 0,02% | 0,30% |
| Staten Island | 0,01% | 0,03% |
| `Unknown` (ID 264) | 1,07% | 0,86% |
| `N/A` (ID 265, Outside of NYC) | 0,15% | 0,40% |

- ID 264/265 chiếm 1,22% pickup và 1,26% drop-off, nên phải là thành viên hợp lệ của `DimTaxiZone`.
- Có 49.932 cặp tuyến PU→DO có thứ tự khác nhau [`distinct_ordered_routes`].
- Pickup và drop-off lệch rõ ở Queens và Brooklyn. Đây là căn cứ cần hai vai trò riêng cho C6/E5.

## 9. Đối chiếu với bản profile của Dũng (cần hợp nhất; Lộc không sửa file của Dũng)

| Vị trí trong [selected_data_profile.md](../dung/selected_data_profile.md) | Nội dung hiện tại | Số đo thực tế | Đề xuất sửa |
|:---|:---|:---|:---|
| Dòng 19–21 | ~77,8 triệu; 2022 ~39,6 triệu; 2023 ~38,2 triệu | 77.966.324; 39.656.098; 38.310.226 (theo tệp) | Thay bằng số đo, ghi rõ theo tệp hay theo pickup |
| Dòng 25 | Pickup lệch tháng ~0,01–0,05% | 0,003% (2.194 dòng) | Thay bằng số đo |
| Dòng 41 | `passenger_count` NULL 2,5–3,8% "trong một số tệp" | 3,43%, ở **mọi** tệp | Thêm: NULL đồng thời ở 5 cột và trùng `payment_type = 0` |
| Dòng 47 | `payment_type` 0% NULL, gán `DimPaymentType` | 0% NULL nhưng **3,43% mang mã 0** ngoài từ điển | Thêm thành viên mã 0 (OD-03) |
| Dòng 38 | `VendorID` "1 hoặc 2" | Có 6 (68.269) và 5 (143) | Thêm thành viên (OD-04) |
| Dòng 53 | `improvement_surcharge` "0.30 hoặc 0.0" | 1,00 từ 12/2022 | Bổ sung mức 1,00 |
| Dòng 55–56 | NULL do "ngoài vùng áp dụng / không qua sân bay" | Cùng khối 3,43% thiếu metadata | Sửa diễn giải: NULL là **không ghi nhận** (OD-11) |
| Dòng 63 | Cước âm 0,15–0,25% | 0,81%; 88,2% có dòng dương tương ứng | Thay số; thêm phát hiện ứng viên cặp đảo |
| Dòng 70 | Cự ly 0 là 1,0–1,8% | 1,73% | Thay bằng số đo |
| Dòng 81 | "0 < duration ≤ 180 phút theo công thức của Phúc" | Phúc không có ngưỡng 180 phút (M7: > 24h là outlier; M9: lọc tốc độ). 84.794 dòng > 180 phút | Xin Phúc xác nhận (OD-07) |
| Dòng 89 | Passenger 0 là 1,0–2,0% | 1,73% | Thay bằng số đo |
| Dòng 98 | Manhattan > 85% | 88,6% pickup / 88,3% drop-off | Thay bằng số đo |
| Dòng 102 | 264/265 chiếm 0,5–1,2% | 1,22% pickup / 1,26% drop-off | Thay bằng số đo |
| (chưa có) | | Schema đổi từ 2023-02; đối soát `total_amount` theo vendor; mức phí thay đổi; trùng lặp | Bổ sung mục mới |
