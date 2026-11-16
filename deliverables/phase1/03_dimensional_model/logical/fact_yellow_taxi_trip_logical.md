# Logical Fact Design: `FactYellowTaxiTrip` (Phase 1)

**Tác giả:** Lộc
**Grain:** một dòng = một bản ghi chuyến đi trong 24 tệp TLC Yellow Taxi 2022–2023, xem [fact_grain_and_process.md](fact_grain_and_process.md)
**Chiều liên kết:** [Reference dimensions (Dũng)](../dung/reference_dimensions_logical.md), [Chiều Date/Time/nhóm](supporting_dimensions_logical.md)
**Công thức chỉ số:** [Metric glossary (Phúc)](../phuc/metric_glossary.md), [Metric decisions (Phúc)](../phuc/metric_decisions.md)
**Bằng chứng số liệu:** [profile_results.json](profile_results.json); tên khóa JSON ghi trong ngoặc vuông

> Đây là thiết kế **logic**: tên thuộc tính, vai trò, ngữ nghĩa, nullability logic và tính cộng dồn. Kiểu dữ liệu và độ chính xác vật lý do Trực chốt.
> Cột "Nguồn" là tên cột Parquet. Từ tệp 2023-02, `airport_fee` đổi tên thành `Airport_fee`; hai cột là cùng một trường logic.
> Mọi tỷ lệ phần trăm tính trên toàn bộ 77.966.324 dòng, trừ khi ghi khác.

---

## 1. Khóa và thuộc tính truy vết

| Thuộc tính logic | Loại | Nguồn / quy tắc | Null | Ghi chú |
|:---|:---|:---|:---:|:---|
| `TripRecordKey` | Surrogate PK | Sinh trong DDS | Không | **Không phải khóa nghiệp vụ**; nguồn không có `trip_id` |
| `SourceFileMonth` | Degenerate dimension | Tháng của tệp nguồn (`YYYY-MM`) | Không | Khác tháng pickup ở 2.194 dòng [`monthly`] |
| `SourceRowNumber` | Degenerate dimension (**đề xuất**, OD-13) | Thứ tự dòng trong tệp, bắt đầu từ 0 | Không | Cùng `SourceFileMonth` tạo định danh duy nhất của bản ghi nguồn |

## 2. Khóa ngoại tới chiều (11 quan hệ, 6 trong đó là role-playing)

| Khóa ngoại | Chiều | Vai trò | Nguồn | Quy tắc gán thành viên đặc biệt |
|:---|:---|:---|:---|:---|
| `PickupDateKey` | `DimDate` | Ngày đón | Phần ngày của `tpep_pickup_datetime` | Ngày ngoài 2021-01-01…2024-12-31 → `-1` (593 dòng) |
| `PickupTimeKey` | `DimTime` | Giờ:phút đón | Phần giờ:phút của `tpep_pickup_datetime` | Luôn có giá trị (0 NULL) |
| `DropoffDateKey` | `DimDate` | Ngày trả | Phần ngày của `tpep_dropoff_datetime` | Ngoài phạm vi → `-1` (455 dòng) [`date_range_vs_dimdate`] |
| `DropoffTimeKey` | `DimTime` | Giờ:phút trả | Phần giờ:phút của `tpep_dropoff_datetime` | Luôn có giá trị |
| `PickupTaxiZoneKey` | `DimTaxiZone` | Vùng đón | `PULocationID` | 264/265 là **thành viên hợp lệ**; NULL hoặc ngoài 1–265 → `-1` (0 dòng) [`location_ids`] |
| `DropoffTaxiZoneKey` | `DimTaxiZone` | Vùng trả | `DOLocationID` | Như vùng đón |
| `VendorKey` | `DimVendor` | Nhà cung cấp TPEP | `VendorID` | Mã 5 (143 dòng) và 6 (68.269 dòng) có xuất hiện; đề xuất mỗi mã một thành viên riêng giữ mã gốc (OD-04, Dũng chốt) |
| `RateCodeKey` | `DimRateCode` | Biểu giá cuối chuyến | `RatecodeID` | NULL (3,43%) → `-1`; mã `99` (347.274 dòng) là thành viên riêng, nhất quán với `DimRateCode` §4.3 của Dũng (OD-05) |
| `PaymentTypeKey` | `DimPaymentType` | Phương thức thanh toán | `payment_type` | Mã `0` (3,43%) đề xuất thành viên riêng, không gộp `-1` (OD-03, Dũng chốt) |
| `PassengerGroupKey` | `DimPassengerGroup` | Nhóm số khách | Dẫn xuất từ `passenger_count` | Xem [chiều hỗ trợ §3](supporting_dimensions_logical.md#3-dimpassengergroup) |
| `DistanceBandKey` | `DimDistanceBand` | Dải cự ly | Dẫn xuất từ `trip_distance` | Xem [chiều hỗ trợ §4](supporting_dimensions_logical.md#4-dimdistanceband) |

- Mọi khóa ngoại **NOT NULL** nhờ thành viên đặc biệt. Quan hệ là *đúng một* thành viên chiều trên mỗi dòng Fact, và *không hoặc nhiều* dòng Fact trên mỗi thành viên chiều.
- **Tuyến đường (C7)** không có chiều riêng. Route là cặp có thứ tự `(PickupTaxiZoneKey, DropoffTaxiZoneKey)`, nên A→B và B→A là hai cặp khác nhau; có 49.932 cặp quan sát được. Không tạo `DimRoute` vì mọi thuộc tính của tuyến (zone, borough ở hai đầu) đã có qua hai vai trò của `DimTaxiZone`.

## 3. Thuộc tính thời điểm và cờ nguồn (degenerate)

| Thuộc tính | Nguồn | Null | Ý nghĩa |
|:---|:---|:---:|:---|
| `PickupDateTime` | `tpep_pickup_datetime` | Không | Timestamp đón gốc, giờ địa phương NYC, không múi giờ |
| `DropoffDateTime` | `tpep_dropoff_datetime` | Không | Timestamp trả gốc |
| `StoreAndForwardFlag` | `store_and_fwd_flag` | Có (3,43%) | `Y`/`N`; NULL là "không ghi nhận" |

Timestamp gốc là bắt buộc vì hai lý do:
1. Thời lượng cần độ chính xác giây, trong khi `DimTime` chỉ ở mức phút.
2. Bản ghi có ngày ngoài phạm vi `DimDate` vẫn giữ được thời điểm thật.

## 4. Measures gốc

| Measure | Nguồn | Đơn vị | Null | Tính cộng dồn | Tổng hợp chuẩn | Ghi chú quan sát |
|:---|:---|:---|:---:|:---|:---|:---|
| `TripRecordCount` | Hằng số 1 | bản ghi | Không | Cộng dồn đầy đủ | `SUM` | Cơ sở cho mọi định nghĩa Trip Count (OD-01) |
| `PassengerCount` | `passenger_count` | người (tài xế nhập) | **Có** | Cộng dồn đầy đủ; NULL bị bỏ qua | `SUM` | NULL 3,43%; 0 là 1,73%; 7–9 có 821 dòng. **Không đổi NULL thành 0** |
| `TripDistanceMiles` | `trip_distance` | dặm | Không | Cộng dồn đầy đủ | `SUM`; trung bình = `SUM / Trip Count` | 0 là 1,73%; > 100 dặm có 2.833 dòng (max 389.678,46) |
| `FareAmount` | `fare_amount` | USD | Không | Cộng dồn đầy đủ | `SUM` | Âm ở 634.550 dòng (0,81%) |
| `ExtraAmount` | `extra` | USD | Không | Cộng dồn đầy đủ | `SUM` | Ở VendorID 1, giá trị có vẻ đã gồm phụ phí ùn tắc/phí sân bay (§6). **Không cộng cùng các cấu phần khác** |
| `MtaTaxAmount` | `mta_tax` | USD | Không | Cộng dồn đầy đủ | `SUM` | Chủ yếu 0,50 hoặc −0,50 |
| `TipAmount` | `tip_amount` | USD | Không | Cộng dồn đầy đủ | `SUM` | Chỉ ghi nhận tip điện tử: 3.533 / 14.168.398 dòng tiền mặt có tip > 0 [`tip_by_payment`] |
| `TollsAmount` | `tolls_amount` | USD | Không | Cộng dồn đầy đủ | `SUM` | |
| `ImprovementSurchargeAmount` | `improvement_surcharge` | USD | Không | Cộng dồn đầy đủ | `SUM` | Mức 0,30 chuyển sang 1,00 từ 12/2022 [`fee_levels_by_pickup_month`] |
| `CongestionSurchargeAmount` | `congestion_surcharge` | USD | **Có** | Cộng dồn đầy đủ; NULL bị bỏ qua | `SUM` | NULL 3,43%, nghĩa là **không ghi nhận** (§6b) |
| `AirportFeeAmount` | `airport_fee` / `Airport_fee` | USD | **Có** | Cộng dồn đầy đủ; NULL bị bỏ qua | `SUM` | NULL 3,43%; mức 1,25 chuyển sang 1,75 từ 04/2023 |
| `TotalAmount` | `total_amount` | USD | Không | Cộng dồn đầy đủ | `SUM` | **Nguồn của Total Revenue (M3, QĐ1 của Phúc)**; không gồm tip tiền mặt |

## 5. Thuộc tính dẫn xuất

Mọi thuộc tính dẫn xuất được tính tất định từ cột gốc trên **cùng dòng**, nên tái tạo được bất cứ lúc nào. Ngưỡng lấy nguyên văn từ [metric_glossary.md](../phuc/metric_glossary.md) của Phúc; ngưỡng nào còn tranh chấp thì ghi rõ.

| Thuộc tính | Công thức | Loại | Phục vụ | Trạng thái |
|:---|:---|:---|:---|:---|
| `TripDurationSeconds` | `DropoffDateTime − PickupDateTime`, tính bằng giây, **giữ cả giá trị âm** | Measure; chỉ cộng dồn trên dòng `IsValidDuration` | M7, C7, E2, E3 | Chốt |
| `IsValidDuration` | `0 < TripDurationSeconds ≤ 86.400` | Cờ | M7 (loại ≤ 0, > 24h là outlier); 77.918.162 dòng thỏa [`duration_speed_filters`] | Theo M7 |
| `IsValidForSpeed` | `TripDurationSeconds ≥ 60` AND `TripDistanceMiles > 0,1` AND `1 ≤ tốc độ ≤ 80 mph` | Cờ | M9, E1; 76.060.704 dòng thỏa | **Tạm theo M9, chờ OD-07** |
| `IsValidForTipRatio` | `payment_type = 1` AND `FareAmount > 0` | Cờ | M6, QĐ2, E1 | Theo QĐ2 |
| `IsNegativeTotalAmount` | `TotalAmount < 0` | Cờ, chỉ là quy tắc nhận diện theo dấu | Lọc đơn giá; Operational Trip Count (OD-01) | Chốt quy tắc; ý nghĩa nghiệp vụ chưa chốt |
| `IsInStudyPeriod` | `PickupDateTime` ∈ [2022-01-01, 2024-01-01) | Cờ | Bộ lọc mặc định của mọi báo cáo; 77.965.701 dòng | Chốt (OD-10 về cách xử lý dòng ngoài kỳ) |
| `ExtraResidualAmount` | `TotalAmount − (Fare + MtaTax + Tip + Tolls + Improvement + coalesce(Congestion,0) + coalesce(AirportFee,0))` | Measure, cộng dồn | Phân rã C8/E3 không đếm trùng (§6) | **Đề xuất, chờ OD-02** |

**Quy tắc tổng hợp cho chỉ số phi cộng dồn.** Fact **không** lưu tốc độ, tip ratio hay revenue/trip ở cấp dòng. Các chỉ số này luôn tính lại từ tử số và mẫu số, không cộng và không lấy trung bình của trung bình:

| Chỉ số | Tử số | Mẫu số | Bộ lọc |
|:---|:---|:---|:---|
| Avg Speed (M9) | `SUM(TripDistanceMiles)` | `SUM(TripDurationSeconds) / 3600` | `IsValidForSpeed` |
| Avg Duration (M7) | `SUM(TripDurationSeconds)` | số dòng | `IsValidDuration` |
| Tip Ratio macro (M6) | `SUM(TipAmount)` | `SUM(FareAmount)` | `IsValidForTipRatio` |
| Tip Ratio cấp chuyến (M6 cách 2) | trung bình của `Tip/Fare` từng dòng | số dòng hợp lệ | `IsValidForTipRatio`, tỷ lệ trong [0, 200%] |
| Revenue per Trip (M10) | `SUM(TotalAmount)` | Trip Count theo OD-01 | `IsInStudyPeriod` |
| Avg Distance (M8) | `SUM(TripDistanceMiles)` | Trip Count theo OD-01 | |

## 6. Ghi chú về các khoản tiền

Mỗi nhận định được gắn nhãn: **[Đo]** = quan sát trực tiếp; **[Suy luận]** = giải thích phù hợp với số đo nhưng chưa có tài liệu TLC xác nhận; **[Mô hình]** = quyết định thiết kế.

**(a) Đối soát `total_amount` với các cấu phần.**

- [Đo] Trên tập `payment_type ≠ 0` (75.288.665 dòng), `total_amount` khác tổng 8 cột thành phần ở 19.567.921 dòng (26,0%), sai số cho phép 0,011 USD [`total_gap_by_vendor`]:

| VendorID | Số dòng | Dòng lệch | Lệch = −congestion | Lệch = −airport_fee | Lệch = −(congestion + airport_fee) |
|:---:|---:|---:|---:|---:|---:|
| 1 | 20.511.594 | 19.405.822 (94,6%) | 18.029.769 | 623.467 | 743.312 |
| 2 | 54.777.071 | 162.099 (0,3%) | 31 | 3.592 | 3 |

- [Suy luận] Với VendorID 1, 99,95% số dòng lệch được giải thích chính xác bằng phụ phí ùn tắc và/hoặc phí sân bay. Điều này **phù hợp với giả thuyết** rằng thiết bị của VendorID 1 ghi các khoản này **cả** trong `extra` **và** trong cột riêng, còn `total_amount` chỉ tính một lần. Nhóm chưa có tài liệu TLC xác nhận trực tiếp giả thuyết này.
- [Mô hình] Total Revenue = `SUM(TotalAmount)`, đúng QĐ1 của Phúc. **Không** tính doanh thu bằng cách cộng các cấu phần.
- [Mô hình, đề xuất OD-02] `ExtraResidualAmount` là **phần dư** được định nghĩa sao cho `Fare + ExtraResidual + MtaTax + Tip + Tolls + Improvement + Congestion + AirportFee = TotalAmount`. Phương trình này **luôn đúng do cách định nghĩa**, không phải một phát hiện. `ExtraResidualAmount` **không phải** cột nguồn, cũng không phải khoản phí do TLC định nghĩa:
  - Với VendorID 2 nó gần bằng `extra`.
  - Với VendorID 1 nó là `extra` trừ phần được cho là trùng.
  - Mọi sai lệch khác của nguồn (làm tròn, lỗi thiết bị) cũng dồn vào phần dư này.

  Nếu dùng cho C8/E3, báo cáo phải ghi rõ đây là "phần dư phụ phí khác".

**(b) Khối bản ghi thiếu metadata.** [Đo] Có 2.677.659 dòng (3,43%) cùng lúc NULL ở `passenger_count`, `RatecodeID`, `store_and_fwd_flag`, `congestion_surcharge`, `airport_fee`. Tập này **trùng đúng** tập `payment_type = 0` (cả hai đếm 2.677.659 dòng) [`null_cooccurrence`]. Đặc điểm:
- Doanh thu vẫn có giá trị hợp lý: median `total_amount` 19,66 USD với VendorID 1 và 25,29 USD với VendorID 2 [`payment0_by_vendor`].
- 73,8% số dòng có `tip_amount > 0` nhưng phương thức thanh toán không xác định, nên bị loại khỏi tip ratio theo QĐ2.
- 1.607 dòng của VendorID 2 có giá trị cực đoan (|fare| > 1.000, tip > 1.000 hoặc cự ly > 100 dặm).
- **Toàn bộ** bản ghi của VendorID 5 (143) và VendorID 6 (68.269) nằm trong khối này [`vendor_5_6_span`].

**(c) NULL ≠ 0.** [Mô hình] Với `congestion_surcharge` và `airport_fee`, NULL nghĩa là thiết bị không gửi giá trị. `SUM` tự bỏ qua NULL, nên tổng tiền giống như coi NULL là 0. Tuy nhiên Fact không ghi đè NULL thành 0, để vẫn phân biệt "không ghi nhận" với "không thu".

## 7. Ánh xạ input cho công thức của Phúc

| Chỉ số (Phúc) | Input trong Fact | Bộ lọc / mẫu số |
|:---|:---|:---|
| M1 Trip Count | `TripRecordCount` (+ `IsNegativeTotalAmount` nếu chọn Operational) | `IsInStudyPeriod`; định nghĩa chờ OD-01 |
| M2 Reported Passengers | `PassengerCount` | NULL tự loại; nhóm qua `PassengerGroupKey` |
| M3 Total Revenue | `TotalAmount` | Không cộng cấu phần |
| M4 Fare Amount | `FareAmount` | |
| M5 Recorded Tip | `TipAmount` | |
| M6 Tip Ratio | `TipAmount`, `FareAmount` | `IsValidForTipRatio` |
| M7 Duration | `TripDurationSeconds` | `IsValidDuration` |
| M8 Distance | `TripDistanceMiles` | |
| M9 Speed | `TripDistanceMiles`, `TripDurationSeconds` | `IsValidForSpeed` (OD-07) |
| M10 Revenue/Trip | `TotalAmount`, `TripRecordCount` | Mẫu số theo OD-01 |
| M11 Popular Route | `PickupTaxiZoneKey`, `DropoffTaxiZoneKey` | Cặp có thứ tự |
| M12 MoM/YoY | Mọi measure cộng dồn + `PickupDateKey` | Đủ 24 tháng; 01/2022 không có MoM; năm 2022 không có YoY trong tập chọn |
| C8/E3 cấu phần | `FareAmount`, `ExtraResidualAmount`, `MtaTaxAmount`, `TipAmount`, `TollsAmount`, `ImprovementSurchargeAmount`, `CongestionSurchargeAmount`, `AirportFeeAmount` | Chờ OD-02 |

## 8. Sơ đồ quan hệ

![Logical star schema của FactYellowTaxiTrip](dds_logical_model.png)

Sơ đồ logic tích hợp vẽ theo ký hiệu crow's foot:
- [dds_logical_model.mmd](dds_logical_model.mmd): mã nguồn Mermaid `erDiagram`, bản chuẩn để chỉnh sửa.
- [dds_logical_model.png](dds_logical_model.png): ảnh render từ file `.mmd`.
- [dds_logical_model.drawio](dds_logical_model.drawio): cùng nội dung, sinh lại từ cùng danh sách bảng.

Ở phía chiều, `||` nghĩa là đúng một; ở phía Fact, `o{` nghĩa là không hoặc nhiều. Sơ đồ mức khái niệm (không có thuộc tính) nằm ở [dds_conceptual_model.png](dds_conceptual_model.png).

Tóm tắt dạng chữ:

```
                 DimDate ──(PickupDateKey, DropoffDateKey)──┐
                 DimTime ──(PickupTimeKey, DropoffTimeKey)──┤
DimTaxiZone ──(PickupTaxiZoneKey, DropoffTaxiZoneKey)───────┤
                 DimVendor ──(VendorKey)────────────────────┤
                 DimRateCode ──(RateCodeKey)────────────────┼── FactYellowTaxiTrip
                 DimPaymentType ──(PaymentTypeKey)──────────┤    (1 dòng = 1 bản ghi nguồn)
                 DimPassengerGroup ──(PassengerGroupKey)────┤
                 DimDistanceBand ──(DistanceBandKey)────────┘
```
