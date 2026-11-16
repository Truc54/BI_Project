# Từ điển dữ liệu vật lý DDS Yellow Taxi (Phase 1)

**Quy ước:** dùng kiểu SQL ANSI tương đối độc lập với hệ quản trị; `BOOLEAN` có thể ánh xạ sang `BIT` ở hệ quản trị không hỗ trợ kiểu này. Dấu thời gian dùng `TIMESTAMP(6) WITHOUT TIME ZONE` vì nguồn là giờ địa phương New York, không kèm múi giờ. `DECIMAL` tránh sai số nhị phân của Parquet `DOUBLE`; độ chính xác dưới đây là đề xuất vật lý, không khẳng định dữ liệu nguồn chính xác hơn thực tế.

**Tên cột:** dùng PascalCase theo mô hình logic của Lộc. Ví dụ `trip_distance` → `TripDistanceMiles`, `total_amount` → `TotalAmount`, `Airport_fee`/`airport_fee` → `AirportFeeAmount`. Tên nguồn được ghi trong phần định nghĩa để truy vết.

**Tóm tắt quan hệ:** `FactYellowTaxiTrip` có mức hạt một dòng nguồn, khóa chính `TripRecordKey` và 11 khóa ngoại bắt buộc. `DimDate`, `DimTime` và `DimTaxiZone` được tham chiếu hai lần theo vai trò đón/trả. Mọi chỉ số tiền/dặm đều ở mức một dòng; tỷ lệ/trung bình được tính từ các chỉ số gốc.

## 1. Bảng Fact `FactYellowTaxiTrip`

`NOT NULL` thể hiện quy tắc cho phép NULL trong DDS sau khi gán thành viên chiều đặc biệt; cột nguồn có thể NULL được ghi riêng. Mọi cột tiền tệ dùng đơn vị USD.

| Cột | Kiểu vật lý | Cho phép NULL? | Khóa / đơn vị | Định nghĩa và ý nghĩa |
|---|---|:---:|---|---|
| `TripRecordKey` | `BIGINT` | Không | PK, khóa thay thế | Khóa kỹ thuật duy nhất do DDS gán; không phải mã chuyến nguồn. |
| `SourceFileMonth` | `DATE` | Không | Thuộc tính suy biến | Ngày đầu tháng của tệp nguồn, ví dụ `2022-01-01`; khác tháng đón ở một số dòng. |
| `SourceRowNumber` | `BIGINT` | Không | Thuộc tính suy biến | Số thứ tự dòng bắt đầu từ 0 trong tệp tháng. Cùng `SourceFileMonth` xác định dòng trong đúng bộ tệp đã chọn. |
| `PickupDateKey` | `INT` | Không | FK → `DimDate.DateKey` | Ngày từ `tpep_pickup_datetime`; ngày ngoài miền chiều ngày dùng `-1`. |
| `PickupTimeKey` | `SMALLINT` | Không | FK → `DimTime.TimeKey` | Giờ/phút đón, mã HHMM 0–2359. |
| `DropoffDateKey` | `INT` | Không | FK → `DimDate.DateKey` | Ngày từ `tpep_dropoff_datetime`; ngày ngoài miền chiều ngày dùng `-1`. |
| `DropoffTimeKey` | `SMALLINT` | Không | FK → `DimTime.TimeKey` | Giờ/phút trả, mã HHMM 0–2359. |
| `PickupTaxiZoneKey` | `INT` | Không | FK → `DimTaxiZone.TaxiZoneKey` | Vai trò vùng đón. ID trong bảng tra cứu 264/265 được giữ là mã vùng hợp lệ; mã thiếu/lỗi dùng -1. |
| `DropoffTaxiZoneKey` | `INT` | Không | FK → `DimTaxiZone.TaxiZoneKey` | Vai trò vùng trả, cùng quy tắc vùng đón. |
| `VendorKey` | `INT` | Không | FK → `DimVendor.VendorKey` | Nhà cung cấp TPEP; mã nguồn ở `DimVendor.VendorID`. |
| `RateCodeKey` | `INT` | Không | FK → `DimRateCode.RateCodeKey` | Biểu giá; mã 99 riêng, NULL/lỗi dùng -1. |
| `PaymentTypeKey` | `INT` | Không | FK → `DimPaymentType.PaymentTypeKey` | Mã thanh toán; mã 0 riêng, NULL/lỗi dùng -1. |
| `PassengerGroupKey` | `SMALLINT` | Không | FK → `DimPassengerGroup.PassengerGroupKey` | Thành viên theo số khách nguồn; NULL → -1, 0 → 0, từ 10 trở lên → 99. |
| `DistanceBandKey` | `SMALLINT` | Không | FK → `DimDistanceBand.DistanceBandKey` | Dải dẫn xuất từ dặm; NULL/âm → -1. |
| `PickupDateTime` | `TIMESTAMP(6) WITHOUT TIME ZONE` | Không | Giờ địa phương New York | Dấu thời gian đầy đủ từ `tpep_pickup_datetime`, giữ độ phân giải nguồn và hỗ trợ ngày ngoài `DimDate`. |
| `DropoffDateTime` | `TIMESTAMP(6) WITHOUT TIME ZONE` | Không | Giờ địa phương New York | Dấu thời gian đầy đủ từ `tpep_dropoff_datetime`. |
| `StoreAndForwardFlag` | `CHAR(1)` | Có | `Y`/`N` | Từ `store_and_fwd_flag`; NULL là không ghi nhận. |
| `TripRecordCount` | `SMALLINT` | Không | bản ghi | Hằng số 1 ở mỗi dòng; cơ sở để đếm bản ghi nguồn, không tự quyết định định nghĩa nghiệp vụ của số chuyến. |
| `PassengerCount` | `SMALLINT` | Có | người | Từ `passenger_count`, do tài xế báo cáo. NULL giữ NULL; 0 vẫn là 0. Hồ sơ mẫu có số nguyên 0–9 và NULL. |
| `TripDistanceMiles` | `DECIMAL(12,2)` | Không | dặm | Từ `trip_distance`, giữ giá trị gốc đến độ chính xác quan sát được; giá trị lớn nhất quan sát được là 389.678,46. |
| `FareAmount` | `DECIMAL(18,4)` | Không | USD | Từ `fare_amount`, cước đo theo đồng hồ; giữ giá trị âm. |
| `ExtraAmount` | `DECIMAL(18,4)` | Không | USD | Từ `extra`; giữ để truy vết. Không cộng đồng thời với các khoản phụ phí riêng khi phân rã vì dữ liệu VendorID 1 có dấu hiệu chồng lấp. |
| `MtaTaxAmount` | `DECIMAL(18,4)` | Không | USD | Từ `mta_tax`. |
| `TipAmount` | `DECIMAL(18,4)` | Không | USD | Từ `tip_amount`; ghi nhận tip điện tử không đầy đủ tip tiền mặt. |
| `TollsAmount` | `DECIMAL(18,4)` | Không | USD | Từ `tolls_amount`. |
| `ImprovementSurchargeAmount` | `DECIMAL(18,4)` | Không | USD | Từ `improvement_surcharge`; giữ các mức thay đổi trong kỳ. |
| `CongestionSurchargeAmount` | `DECIMAL(18,4)` | Có | USD | Từ `congestion_surcharge`; NULL là không ghi nhận, không đổi thành 0. |
| `AirportFeeAmount` | `DECIMAL(18,4)` | Có | USD | `airport_fee` đến 2023-01, `Airport_fee` từ 2023-02; cùng một trường logic. NULL là không ghi nhận. |
| `TotalAmount` | `DECIMAL(18,4)` | Không | USD | Từ `total_amount`; chỉ số chuẩn cho tổng doanh thu. Không gồm tip tiền mặt. |
| `TripDurationSeconds` | `BIGINT` | Không | giây | `DropoffDateTime - PickupDateTime`; số có dấu, giữ thời lượng âm/0. Dùng làm chỉ số thời lượng có điều kiện, không thay timestamp. |
| `ExtraResidualAmount` | `DECIMAL(18,4)` | Không* | USD | **Đề xuất OD-02:** `TotalAmount - (FareAmount + MtaTaxAmount + TipAmount + TollsAmount + ImprovementSurchargeAmount + COALESCE(CongestionSurchargeAmount,0) + COALESCE(AirportFeeAmount,0))`. Là phần dư để phân rã tổng tiền, không phải khoản phí do TLC quy định; chỉ lưu thành cột nếu Phúc duyệt. |
| `IsValidDuration` | `BOOLEAN` | Không | cờ | `TripDurationSeconds > 0 AND TripDurationSeconds <= 86400`. |
| `IsValidForSpeed` | `BOOLEAN` | Không | cờ | Tạm theo M9: thời lượng ≥60 giây, quãng đường >0,1 dặm, tốc độ 1–80 mph. Ngưỡng còn chờ Phúc (OD-07). |
| `IsValidForTipRatio` | `BOOLEAN` | Không | cờ | `payment_type = 1 AND FareAmount > 0`; phù hợp với cách tính tỷ lệ tiền tip trên giao dịch thẻ đã thống nhất. |
| `IsNegativeTotalAmount` | `BOOLEAN` | Không | cờ | `TotalAmount < 0`; chỉ phân loại theo dấu, không khẳng định đây là giao dịch đảo. |
| `IsInStudyPeriod` | `BOOLEAN` | Không | cờ | Timestamp đón trong `[2022-01-01, 2024-01-01)`. |

\* Nếu chưa thông qua OD-02, bỏ cột `ExtraResidualAmount`; không dùng NULL để giả lập một khoản phí. Giữ timestamp/tiền/khoảng cách nguồn; không áp đặt `CHECK` để loại giá trị âm hoặc ngoại lai.

### Khóa và chỉ mục ở mức mô hình

- PK: `TripRecordKey`.
- FK: 11 khóa ngoại theo vai trò/chiều đã nêu, tất cả `NOT NULL`.
- Khóa dòng nguồn đề xuất: `UNIQUE (SourceFileMonth, SourceRowNumber)` trên bộ tệp không bị thay đổi. Mã băm tệp tiếp tục được đối chiếu với tệp kê khai bên ngoài Fact.
- Phase 1 chưa quy định chỉ mục hay phân vùng bảng; đây là đặc tả mô hình, không phải thiết kế triển khai.

## 2. Bảng chiều ngày `DimDate`

Mức hạt: một dòng mỗi ngày từ 2021-01-01 đến 2024-12-31, cộng thành viên đặc biệt -1. Khóa ngày là khóa thông minh `YYYYMMDD`, không phải dãy khóa thay thế. Ngày ngoài miền được ánh xạ về -1; timestamp gốc vẫn được giữ trong Fact.

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `DateKey` | `INT` | Không | PK; `YYYYMMDD`, không xác định = -1 | Khóa thông minh của ngày lịch. |
| `FullDate` | `DATE` | Có | Khóa nghiệp vụ ngày lịch | Ngày đầy đủ; NULL ở thành viên -1. |
| `DayOfMonth` | `SMALLINT` | Có | 1–31 | Ngày trong tháng. |
| `DayOfWeekNumber` | `SMALLINT` | Có | ISO 1–7 | Thứ Hai=1 đến Chủ nhật=7. |
| `DayOfWeekName` | `VARCHAR(9)` | Có | tên thứ | Tên hiển thị của ngày trong tuần. |
| `IsWeekend` | `BOOLEAN` | Có | — | Cuối tuần; NULL ở thành viên ngày không xác định. |
| `MonthNumber` | `SMALLINT` | Có | 1–12 | Tháng lịch. |
| `MonthName` | `VARCHAR(9)` | Có | — | Tên tháng. |
| `YearMonth` | `CHAR(7)` | Có | `YYYY-MM` | Nhãn/khóa nhóm tháng. |
| `Quarter` | `SMALLINT` | Có | 1–4 | Quý lịch. |
| `Year` | `SMALLINT` | Có | — | Năm lịch. |
| `DaysInMonth` | `SMALLINT` | Có | 28–31 | Dùng chuẩn hóa so sánh các tháng khác độ dài. |
| `IsInStudyPeriod` | `BOOLEAN` | Không | — | TRUE từ 2022-01-01 đến 2023-12-31; FALSE ngoài kỳ và ở thành viên -1. |

Không đưa cờ ngày lễ vào bản vật lý cơ sở: nó không đến từ tệp taxi/bảng tra cứu và chưa có nguồn lịch được thống nhất.

## 3. Bảng chiều giờ `DimTime`

Mức hạt: một dòng mỗi phút trong ngày (00:00–23:59), khóa thông minh `HHMM` (00:00 có khóa 0). Không cần thành viên không xác định vì timestamp đón/trả trong mẫu không NULL.

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `TimeKey` | `SMALLINT` | Không | PK; `HHMM` 0–2359 | Khóa thông minh theo giờ/phút. |
| `Hour24` | `SMALLINT` | Không | 0–23 | Giờ trong ngày. |
| `Minute` | `SMALLINT` | Không | 0–59 | Phút trong giờ. |
| `HourLabel` | `VARCHAR(11)` | Không | — | Nhãn giờ hiển thị, ví dụ `17:00–17:59`. |
| `DaypartCode` | `VARCHAR(8)` | Có | đề xuất 5 mã | Mã khung giờ trong ngày; ranh giới chưa được Phúc duyệt. |
| `DaypartName` | `VARCHAR(16)` | Có | — | Tên khung giờ; chỉ dùng sau khi thống nhất OD-08. |
| `DaypartSortOrder` | `SMALLINT` | Có | 1–5 | Thứ tự hiển thị khung giờ. |

Đề xuất chưa chốt: NIGHT (đêm) 00–05, MORN (sáng) 06–10, MID (trưa) 11–13, AFT (chiều) 14–17, EVE (tối) 18–23. Không đưa cờ khung phụ phí TLC vào mô hình cơ sở vì cần kiểm tra thêm ngày áp dụng và nguồn chính sách.

## 4. Bảng chiều vùng taxi `DimTaxiZone`

Một dòng cho mỗi trong 265 ID của bảng tra cứu và một thành viên -1. `TaxiZoneKey` là khóa thay thế số nguyên, khác với `LocationID` là mã TLC. Khóa thay thế -1 dành cho mã NULL/ngoài danh mục; ID nguồn 264 và 265 có thành viên riêng.

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `TaxiZoneKey` | `INT` | Không | PK; khóa thay thế, -1 = thiếu/không hợp lệ | Khóa DDS không mang ý nghĩa địa lý. |
| `LocationID` | `SMALLINT` | Có | Khóa nghiệp vụ duy nhất khi khác NULL; 1–265 | Mã TLC trong bảng tra cứu. NULL ở thành viên -1. |
| `Borough` | `VARCHAR(50)` | Không | — | Tên quận nguyên văn từ bảng tra cứu; thành viên -1 dùng nhãn riêng `Thiếu mã vùng`. |
| `Zone` | `VARCHAR(100)` | Không | — | Tên vùng nguyên văn; thành viên -1 ghi `Thiếu/không hợp lệ`. |
| `ServiceZone` | `VARCHAR(50)` | Không | — | Phân vùng dịch vụ theo bảng tra cứu, giữ cả `N/A`. |
| `HasGeometry` | `BOOLEAN` | Không | — | TRUE cho ID 1–263; FALSE cho ID 264, 265 và -1. |

Giữ nguyên nhãn nguồn: 264 = (`Unknown`, `N/A`, `N/A`), 265 = (`N/A`, `Outside of NYC`, `N/A`). Không tạo polygon cho hai ID này. Bản ghi -1 không được gộp vào quận `Unknown` của ID 264.

## 5. Bảng chiều nhà cung cấp `DimVendor`

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `VendorKey` | `INT` | Không | PK; khóa thay thế, -1 = thiếu/không hợp lệ | Khóa DDS; không bắt buộc trùng với VendorID. |
| `VendorID` | `SMALLINT` | Có | Khóa nghiệp vụ duy nhất khi khác NULL | Mã nguồn. Thành viên -1 có NULL; giữ riêng các mã 1, 2, 5, 6. |
| `VendorName` | `VARCHAR(100)` | Không | — | Tên nhà cung cấp hoặc mô tả chưa xác minh cho mã 5/6. |
| `VendorShortName` | `VARCHAR(50)` | Không | — | CMT, VeriFone (VTS/Curb), Mã 5, Mã 6 hoặc Thiếu. |

VendorID 1 = Creative Mobile Technologies, LLC (CMT); 2 = VeriFone Inc. (tên ngắn cần thống nhất VTS/Curb); 5 và 6 được giữ riêng, chưa gán tên pháp nhân TLC. Không gộp các mã này về -1.

## 6. Bảng chiều biểu giá `DimRateCode`

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `RateCodeKey` | `INT` | Không | PK; khóa thay thế, -1 = NULL/lỗi | Khóa DDS. |
| `RatecodeID` | `SMALLINT` | Có | Khóa nghiệp vụ duy nhất khi khác NULL | Mã nguồn; các thành viên 1–6, 99; NULL ở -1. |
| `RateDescription` | `VARCHAR(100)` | Không | — | Mô tả TLC; mã 99 ghi Special/Flexible Rate (biểu giá đặc biệt/linh hoạt, mã 99), -1 ghi Thiếu/không hợp lệ. |
| `RateCategory` | `VARCHAR(50)` | Không | — | Giá trị nhóm lưu trong cột: Standard (tiêu chuẩn), Airport (sân bay), Out of Town (ngoại thành), Negotiated (thỏa thuận), Special (đặc biệt), Unknown (không rõ). |
| `IsFlatFare` | `BOOLEAN` | Không | — | TRUE cho mã JFK 2 theo mô hình logic; FALSE cho các thành viên khác. |

RatecodeID 99 là mã hợp lệ riêng, khác thành viên -1 dành cho NULL. Giữ thành viên chuẩn mã 6 dù mẫu 2022–2023 không có giá trị đó.

## 7. Bảng chiều phương thức thanh toán `DimPaymentType`

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `PaymentTypeKey` | `INT` | Không | PK; khóa thay thế, -1 = NULL/lỗi | Khóa DDS. |
| `PaymentTypeID` | `SMALLINT` | Có | Khóa nghiệp vụ duy nhất khi khác NULL | Mã nguồn 0–6; NULL ở -1. |
| `PaymentDescription` | `VARCHAR(100)` | Không | — | Mô tả TLC hoặc nhãn chưa có trong từ điển. |
| `PaymentGroup` | `VARCHAR(50)` | Không | — | Giá trị nhóm lưu trong cột: Electronic (điện tử), Cash (tiền mặt), Non-Revenue (không doanh thu), Exception (ngoại lệ), Unknown (không xác định). |
| `AllowsElectronicTip` | `BOOLEAN` | Không | — | TRUE chỉ cho payment type 1; cờ dùng trong phân tích tỷ lệ tip. |

Mã 0 có 2.677.659 dòng trong profile nhưng chưa có mô tả TLC 2022–2023; giữ nhãn `Mã 0 (chưa có trong từ điển)`. Giữ các thành viên 1–6; mã 6 không quan sát được. `-1` chỉ dành cho NULL/ngoài miền.

## 8. Bảng chiều nhóm khách `DimPassengerGroup`

Khóa thông minh bằng giá trị khách báo cáo. NULL được biểu diễn bằng khóa -1; giá trị 0 là thành viên riêng nhưng cùng tổng hợp vào nhóm Không xác định. Thành viên 99 dự phòng để mọi số khách từ 10 trở lên vào nhóm Lớn.

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `PassengerGroupKey` | `SMALLINT` | Không | PK, khóa thông minh; -1, 0–9, 99 | Khóa bằng số khách cho 0–9; -1 cho NULL; 99 là nhóm từ 10 trở lên, không phải giá trị nguồn. |
| `PassengerCountValue` | `SMALLINT` | Có | Giá trị hiển thị | NULL cho khóa -1; giữ 0–9; 99 biểu thị từ 10 trở lên. |
| `GroupCode` | `VARCHAR(16)` | Không | SOLO/SMALL/LARGE/UNKNOWN | Mã nhóm theo quyết định chỉ số đo của Phúc. |
| `GroupName` | `VARCHAR(40)` | Không | — | Một khách (1), nhóm nhỏ (2–4), nhóm lớn (5+), không xác định (0 hoặc NULL). |
| `GroupSortOrder` | `SMALLINT` | Không | 1–4 | Thứ tự nhóm hiển thị. |
| `IsReportedCount` | `BOOLEAN` | Không | — | FALSE cho NULL và 0; TRUE từ 1 trở lên. |

## 9. Bảng chiều dải cự ly `DimDistanceBand`

Khóa thay thế từ 1–5 và -1. Khoảng cách gốc vẫn nằm ở Fact. Với các ranh giới dưới đây, cận trên được tính vào dải; cận dưới của các dải sau “Rất ngắn” không được tính vào dải.

| Cột | Kiểu | Cho phép NULL? | Khóa / miền | Định nghĩa |
|---|---|:---:|---|---|
| `DistanceBandKey` | `SMALLINT` | Không | PK; -1, 1–5 | -1 cho NULL/âm. |
| `BandCode` | `VARCHAR(12)` | Không | — | UNKNOWN, VSHORT, SHORT, MEDIUM, LONG, VLONG. |
| `BandName` | `VARCHAR(32)` | Không | — | Rất ngắn, Ngắn, Trung bình, Dài, Rất dài hoặc Không xác định. |
| `LowerBoundMiles` | `DECIMAL(12,2)` | Có | dặm | Các mốc 0, 1, 3, 5, 10 tương ứng; NULL ở nhóm không xác định. |
| `UpperBoundMiles` | `DECIMAL(12,2)` | Có | dặm | Các mốc 1, 3, 5, 10; NULL ở dải mở >10 và nhóm không xác định. |
| `SortOrder` | `SMALLINT` | Không | 1–5, nhóm không xác định=9 | Thứ tự hiển thị. |

Quy tắc gán dải: `0 <= d <= 1`; `1 < d <= 3`; `3 < d <= 5`; `5 < d <= 10`; `d > 10`; NULL hoặc `d < 0` → -1. Có 2.833 dòng trên 100 dặm (lớn nhất 389.678,46) vẫn nằm trong dải Rất dài theo quyết định hiện hành; chưa tách dải ngoại lai riêng.

## 10. Ràng buộc nghiệp vụ và ánh xạ tên

- Các khóa nghiệp vụ mã nguồn trong `DimTaxiZone`, `DimVendor`, `DimRateCode`, `DimPaymentType` phải duy nhất khi có giá trị; thành viên không xác định giữ khóa nghiệp vụ NULL. `DimDate.FullDate` duy nhất khi có giá trị; `DateKey = YYYYMMDD`. `DimTime.TimeKey = HHMM` duy nhất.
- Mọi khóa ngoại Fact đều `NOT NULL` và tham chiếu đúng một dòng chiều, kể cả thành viên không xác định. ID 264/265, PaymentTypeID 0, VendorID 5/6 và RatecodeID 99 không phải giá trị không xác định.
- Ánh xạ tên chỉ số: `trip_record_count` → `TripRecordCount`; Trip Count trong bảng thuật ngữ là phép tổng hợp được chốt riêng dựa trên chỉ số này; `trip_distance` → `TripDistanceMiles`; `fare_amount` → `FareAmount`; `total_amount` → `TotalAmount`.
- Kiểu/độ chính xác được thiết kế để dễ ánh xạ giữa các hệ quản trị. Trước khi triển khai, cần xác nhận hệ quản trị và cách chuyển `DOUBLE` sang `DECIMAL`; tránh làm tròn mất phần lẻ hoặc thay đổi giá trị âm/ngoại lai đã quan sát.
