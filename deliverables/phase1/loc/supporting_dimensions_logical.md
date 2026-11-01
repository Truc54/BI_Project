# Logical Supporting Dimensions: Date, Time, Passenger Group, Distance Band (Phase 1)

**Tác giả:** Lộc (đồng thiết kế với Dũng, Gói D)
**Bổ sung cho:** [Reference dimensions của Dũng](../dung/reference_dimensions_logical.md) (`DimTaxiZone`, `DimVendor`, `DimRateCode`, `DimPaymentType`)
**Căn cứ:** [Analysis grain matrix (Phúc)](../phuc/analysis_grain_matrix.md) §3, [Metric decisions (Phúc)](../phuc/metric_decisions.md) QĐ3–QĐ4

> Mức logic: thuộc tính, khóa, phân cấp, thành viên đặc biệt. Kiểu dữ liệu vật lý do Trực chốt.
> Các cột "Số dòng quan sát" tính trên **toàn bộ 77.966.324 dòng** của 24 tệp, lấy từ [profile_results.json](profile_results.json).

---

## 0. Chiến lược khóa của toàn mô hình

| Chiều | Loại khóa chính | Thành viên đặc biệt | Lý do |
|:---|:---|:---|:---|
| `DimDate` | **Smart key** `YYYYMMDD` | `-1` = ngày ngoài phạm vi / không hợp lệ | Quy ước Kimball cho chiều ngày; khóa ổn định, dễ đọc và dễ phân vùng |
| `DimTime` | **Smart key** `HHMM` | Không cần (timestamp không NULL) | Miền cố định 1.440 phút |
| `DimPassengerGroup` | **Smart key** = giá trị `passenger_count` | `-1` = NULL; `99` = ≥ 10 (dự phòng) | Miền nhỏ, cố định; khóa trùng giá trị giúp đối chiếu |
| `DimDistanceBand` | Surrogate (1…5) | `-1` = NULL hoặc âm | Dải là khái niệm phân tích, không có mã nguồn |
| `DimTaxiZone`, `DimVendor`, `DimRateCode`, `DimPaymentType` (Dũng) | Surrogate + business key mã gốc | `-1` = thiếu mã hoặc mã ngoài danh mục | Theo [reference_dimensions_logical.md](../dung/reference_dimensions_logical.md) |

**Quy ước chung:** `-1` luôn có nghĩa "không có giá trị hợp lệ để gán". Nó không bao giờ trùng với một mã nguồn hợp lệ. Ví dụ, `LocationID = 264` ("Unknown" trong lookup) là thành viên thật, **khác** với `TaxiZoneKey = -1`.

## 1. `DimDate` (role-playing: Pickup Date, Drop-off Date)

**Grain:** một dòng = một ngày lịch.
**Phạm vi:** 2021-01-01 … 2024-12-31 (1.461 ngày), cộng thành viên `-1`.

Phạm vi rộng hơn 2022–2023 để chứa các cuốc vắt qua ranh giới kỳ: 24 dòng có pickup năm 2021 và 6 dòng có pickup năm 2024 [`pickup_year_distribution`]. Các ngày ngoài phạm vi trỏ về `-1`, còn timestamp gốc vẫn giữ trong Fact:
- 593 dòng theo pickup, năm 2001–2014;
- 455 dòng theo drop-off, sớm nhất 1970-01-20 [`date_range_vs_dimdate`].

| Thuộc tính | Ví dụ | Mục đích |
|:---|:---|:---|
| `DateKey` (PK) | `20230615` | Smart key; `-1` cho ngày ngoài phạm vi |
| `FullDate` | 2023-06-15 | |
| `DayOfMonth` | 15 | C1 (mức ngày) |
| `DayOfWeekNumber` | 4 (ISO: 1 = Thứ Hai) | C4, sắp xếp |
| `DayOfWeekName` | Thursday | C4 |
| `IsWeekend` | FALSE | C4, E2 |
| `MonthNumber` | 6 | C3, C4, E2 |
| `MonthName` | June | |
| `YearMonth` | 2023-06 | C3, C6, E4 (khóa so sánh kỳ) |
| `Quarter` | 2 | C8, E3 |
| `Year` | 2023 | C1, E4 |
| `DaysInMonth` | 30 | E2, E4: chuẩn hóa theo ngày (tháng 5 có 31 ngày, tháng 6 có 30) |
| `IsInStudyPeriod` | TRUE | TRUE với 2022-01-01 … 2023-12-31 |

**Phân cấp:** `Year → Quarter → Month → Day`. Thuộc tính song song: `DayOfWeek`, `IsWeekend`.

> **Đã chốt:** không đưa ngày lễ (`IsUSFederalHoliday`, `HolidayName`) vào Phase 1 vì chưa có lịch tham chiếu được quản trị.

## 2. `DimTime` (role-playing: Pickup Time, Drop-off Time)

**Grain:** một dòng = một phút trong ngày (1.440 dòng). Mức phút đáp ứng phân cấp `Daypart → Hour → Minute` của Phúc ([analysis_grain_matrix.md](../phuc/analysis_grain_matrix.md) dòng 38). Thời lượng chính xác đến giây được tính từ timestamp gốc trong Fact, không dùng chiều này.

| Thuộc tính | Ví dụ | Mục đích |
|:---|:---|:---|
| `TimeKey` (PK) | `1745` | Smart key `HHMM` (0 … 2359) |
| `Hour24` | 17 | C2, C4, E5 |
| `Minute` | 45 | |
| `HourLabel` | 17:00–17:59 | Hiển thị |
| `DaypartCode` / `DaypartName` | AFT / Chiều | C4, E5. Ranh giới đã chốt (OD-08) |
| `DaypartSortOrder` | 4 | Sắp xếp |

**Ranh giới Daypart (đã chốt, OD-08).** Phúc nêu tên 5 khung; nhóm thông qua nguyên văn mốc giờ do Lộc đề xuất. Hai cờ khung phụ phí (`IsPeakSurchargeWindow`, `IsOvernightSurchargeWindow`) từng là thuộc tính tùy chọn đã được bỏ khỏi mô hình cuối.

| Sort | Code | Tên | Khung giờ |
|:---:|:---|:---|:---|
| 1 | NIGHT | Đêm | 00:00 – 05:59 |
| 2 | MORN | Sáng | 06:00 – 10:59 |
| 3 | MID | Trưa | 11:00 – 13:59 |
| 4 | AFT | Chiều | 14:00 – 17:59 |
| 5 | EVE | Tối | 18:00 – 23:59 |

**Phân cấp:** `Daypart → Hour → Minute`. Không cần thành viên `-1`, vì timestamp không bao giờ NULL (0 dòng NULL).

## 3. `DimPassengerGroup`

**Grain:** một dòng = một **giá trị** `passenger_count` có thể gặp, kèm nhóm của giá trị đó. Thiết kế theo giá trị (không theo nhóm) để vừa nhóm được (C5), vừa drill xuống số khách cụ thể. Fact vẫn giữ `PassengerCount` gốc.

| `PassengerGroupKey` | `PassengerCountValue` | `GroupCode` | `GroupName` | `GroupSortOrder` | `IsReportedCount` | Số dòng quan sát |
|:---:|:---:|:---|:---|:---:|:---:|---:|
| -1 | NULL | UNKNOWN | Không xác định / bằng 0 – chi tiết: không ghi nhận | 4 | FALSE | 2.677.659 |
| 0 | 0 | UNKNOWN | Không xác định / bằng 0 – chi tiết: tài xế nhập 0 | 4 | FALSE | 1.346.349 |
| 1 | 1 | SOLO | Đi một mình (1) | 1 | TRUE | 56.084.878 |
| 2, 3, 4 | 2, 3, 4 | SMALL | Nhóm nhỏ (2–4) | 2 | TRUE | 15.911.074 |
| 5 … 9 | 5 … 9 | LARGE | Nhóm lớn (5+) | 3 | TRUE | 1.946.364 |
| 99 | ≥ 10 | LARGE | Nhóm lớn (5+) – dự phòng, ngoài miền quan sát | 3 | TRUE | 0 |

- Mỗi giá trị 2, 3, 4, 5 … 9 là một dòng riêng; các dòng trên chỉ gộp để trình bày.
- Quy tắc nhóm đúng nguyên văn Quyết định 3 của Phúc. Nhóm 4 "Không xác định (Unknown / Zero)" gồm `0` **hoặc** NULL, nên hai thành viên chi tiết `-1` và `0` **cùng roll-up** vào `GroupCode = UNKNOWN`. Tách hai thành viên chỉ để giữ chi tiết, không tạo nhóm mới: NULL trùng khối bản ghi thiếu metadata (`payment_type = 0`), còn 0 là tài xế không bấm.

**Phân cấp:** `GroupName → PassengerCountValue`.

## 4. `DimDistanceBand`

**Grain:** một dòng = một dải cự ly theo Quyết định 4 của Phúc. Fact vẫn giữ `TripDistanceMiles` gốc, nên tổng và trung bình cự ly luôn tính trên số dặm thật.

| `DistanceBandKey` | `BandCode` | `BandName` | `LowerBoundMiles` (cận dưới) | `UpperBoundMiles` (cận trên) | `SortOrder` | Số dòng quan sát | Tỷ trọng |
|:---:|:---|:---|:---|:---|:---:|---:|---:|
| 1 | VSHORT | Rất ngắn | ≥ 0 | ≤ 1,0 | 1 | 17.708.739 | 22,7% |
| 2 | SHORT | Ngắn | > 1,0 | ≤ 3,0 | 2 | 37.358.211 | 47,9% |
| 3 | MEDIUM | Trung bình | > 3,0 | ≤ 5,0 | 3 | 9.371.132 | 12,0% |
| 4 | LONG | Dài | > 5,0 | ≤ 10,0 | 4 | 6.886.654 | 8,8% |
| 5 | VLONG | Rất dài | > 10,0 | — | 5 | 6.641.588 | 8,5% |
| -1 | UNKNOWN | Không xác định | NULL hoặc < 0 | | 9 | 0 | 0% |

Tổng năm dải bằng đúng 77.966.324 dòng [`distance_bands`; dải VLONG = `10-100` + `>100`].

- Dải "Rất ngắn" gồm 1.347.516 dòng có `trip_distance = 0`. Muốn tách nhóm này, lọc trực tiếp `TripDistanceMiles = 0` trên Fact.
- Dải "Rất dài" gồm 2.833 dòng > 100 dặm (max 389.678,46). **Đã chốt (OD-09):** giữ dải > 10 dặm là dải mở, không thêm dải "Bất thường"; khi phân tích độ nhạy, lọc trực tiếp `TripDistanceMiles > 100` trên Fact.

## 5. Tương quan với các chiều của Dũng

| Chiều | Người dẫn dắt | Kết quả chốt (xem [quyết định](logical_model_decisions.md) §2) |
|:---|:---|:---|
| `DimTaxiZone` | Dũng | Giữ nguyên lookup 264/265; `-1` = "Thiếu mã vùng (Missing)" (OD-06) |
| `DimVendor` | Dũng | VendorID 5, 6 là member riêng; VendorID 2 = "VeriFone Inc. (VeriFone / Curb / VTS)" (OD-04) |
| `DimRateCode` | Dũng | 99 là member riêng, nhãn "Special/Flexible Rate" (OD-05) |
| `DimPaymentType` | Dũng | Mã 0 là member chính thức; mã 6 vẫn giữ dù không quan sát được (OD-03) |
| `DimDate`, `DimTime`, `DimPassengerGroup`, `DimDistanceBand` | Lộc | Tài liệu này |
