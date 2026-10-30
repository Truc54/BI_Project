# Analysis Grain Matrix & Hierarchy Paths (Phúc - Phase 1)

## 1. Mục đích
Tài liệu này xác định ma trận mức hạt đầu ra (Output Grain), các đường dẫn phân cấp phân tích (Roll-up / Drill-down Paths) và phân loại tính chất tính toán của các chỉ số (Measure Classification) cho toàn bộ 13 câu hỏi nghiệp vụ (C1–C8 và E1–E5).

Tài liệu này là căn cứ kỹ thuật để Dũng và Lộc xây dựng lược đồ Logical Star Schema và Trực kiểm thử trên lược đồ Physical DDS.

---

## 2. Bảng Ma trận Mức hạt & Phân cấp (Analysis Grain Matrix)

| Mã YC | Mô tả ngắn | Mức hạt đầu ra mong muốn (Desired Output Grain) | Các chiều phân tích tham gia (Dimensions Involved) | Đường dẫn Phân cấp (Roll-up / Drill-down Paths) | Thước đo chính (Measures) | Phân loại thước đo (Measure Type) |
|---|---|---|---|---|---|---|
| **C1** | Chuyến & khách theo thời gian | `Pickup Date` (hoặc Month / Year) | `DimDate` (Role: Pickup Date) | `Year` $\rightarrow$ `Month` $\rightarrow$ `Day` | - `Trip Count`<br>- `Reported Passengers` | Additive |
| **C2** | Doanh thu theo quận, nhà cung cấp & thời điểm | `Pickup Borough` $\times$ `Vendor` $\times$ `Date` $\times$ `Hour` | - `DimTaxiZone` (Pickup)<br>- `DimVendor`<br>- `DimDate` (Pickup)<br>- `DimTime` (Pickup) | - Địa lý: `Borough` $\rightarrow$ `Zone`<br>- Thời gian: `Year` $\rightarrow$ `Month` $\rightarrow$ `Day` $\rightarrow$ `Hour` | - `Total Revenue`<br>- `Fare Amount`<br>- `Trip Count` | Additive |
| **C3** | Phương thức thanh toán theo quận & tháng | `Pickup Borough` $\times$ `Payment Type` $\times$ `Year-Month` | - `DimTaxiZone` (Pickup)<br>- `DimPaymentType`<br>- `DimDate` (Pickup) | - Địa lý: `Borough` $\rightarrow$ `Zone`<br>- Lịch: `Year` $\rightarrow$ `Month`<br>- Thanh toán: `Payment Type Group` $\rightarrow$ `Payment Type` | - `Trip Count`<br>- `% Payment Share` | - Additive (Count)<br>- Calculated (Share) |
| **C4** | Chuyến đón & trả theo khung giờ, thứ, tháng | - Khung giờ: `Hour` / `Daypart`<br>- Thứ: `DayOfWeek`<br>- Tháng: `Month`<br>- Vai trò: `Event Role` | - `DimDate` (Pickup & Drop-off)<br>- `DimTime` (Pickup & Drop-off) | - Trong ngày: `Daypart` $\rightarrow$ `Hour`<br>- Tuần: `DayOfWeek`<br>- Năm: `Year` $\rightarrow$ `Month` | - `Pickup Trip Count`<br>- `Drop-off Trip Count` | Additive (riêng theo từng Role) |
| **C5** | Nhóm khách, biểu phí & cự ly | `Passenger Group` $\times$ `Rate Code` $\times$ `Distance Band` | - `DimPassengerGroup`<br>- `DimRateCode`<br>- `DimDistanceBand` | - Nhóm khách: `Group (1, 2-4, 5+)`<br>- Biểu phí: `Rate Code ID`<br>- Cự ly: `Distance Band` $\rightarrow$ Chi tiết dặm | - `Trip Count`<br>- `Reported Passengers`<br>- `Total Distance`<br>- `Avg Distance` | - Additive (Count, Total Dist)<br>- Non-additive (Avg Dist) |
| **C6** | Vận hành cấp quận/khu vực | `Borough` $\times$ `Zone` $\times$ `Year-Month` | - `DimTaxiZone` (Pickup & Drop-off roles)<br>- `DimDate` | `Borough` $\rightarrow$ `Zone` $\rightarrow$ `LocationID` | - `Trip Count`<br>- `Total Revenue`<br>- `Avg Fare`<br>- `Avg Distance`<br>- `Net Flow` | - Additive (Count, Rev)<br>- Non-additive (Avg Fare, Dist)<br>- Calculated (Net Flow) |
| **C7** | Top N tuyến đường phổ biến | `Pickup Zone` $\times$ `Drop-off Zone` (Ordered Pair) | - `DimTaxiZone` (Pickup Role)<br>- `DimTaxiZone` (Drop-off Role) | Cặp Zone `(PULocationID, DOLocationID)` $\rightarrow$ Cặp Borough `(PUBorough, DOBorough)` | - `Trip Count`<br>- `Rank`<br>- `Avg Duration`<br>- `Total Revenue` | - Additive (Count, Rev)<br>- Non-additive (Rank, Duration) |
| **C8** | Tổng doanh thu & cấu phần | `Year` $\times$ `Month` | - `DimDate`<br>- `FactYellowTaxiTrip` | `Year` $\rightarrow$ `Quarter` $\rightarrow$ `Month` $\rightarrow$ `Day` | - `Total Revenue`<br>- `Fare Amount`<br>- `Extra`<br>- `MTA Tax`<br>- `Tip Amount`<br>- `Tolls Amount`<br>- `Improvement Surcharge`<br>- `Congestion Surcharge`<br>- `Airport Fee` | Additive (toàn bộ cấu phần) |
| **E1** | Tip ratio & Vận tốc theo loại biểu phí | `Rate Code` | `DimRateCode` | `Rate Code ID` $\rightarrow$ `Rate Description` | - `Average Tip Ratio (%)`<br>- `Average Speed (mph)`<br>- `Trip Count` | - Non-additive (Tip Ratio, Speed)<br>- Additive (Trip Count) |
| **E2** | So sánh Tháng 5 vs Tháng 6 & phân rã | `Year` $\times$ `Month (05 vs 06)` $\times$ Phân khúc phân rã | - `DimDate`<br>- `DimTaxiZone`<br>- `DimRateCode`<br>- `DimVendor` | `Month` $\rightarrow$ `Borough` $\rightarrow$ `Rate Code` $\rightarrow$ `Hour` | - `Total Revenue`<br>- `Revenue Delta ($ và %)`<br>- `Revenue per Trip`<br>- `Trip Count` | - Additive (Total Rev, Count)<br>- Calculated (Delta, Rev/Trip) |
| **E3** | Phân rã động lực tăng doanh thu/chuyến | `Year-Month Period` | - `DimDate`<br>- `Fact Measures` | `Year` $\rightarrow$ `Quarter` $\rightarrow$ `Month` | - `Revenue per Trip`<br>- `Fare per Trip`<br>- `Surcharge per Trip`<br>- `Tip per Trip`<br>- `Tolls per Trip`<br>- `Avg Distance`<br>- `Avg Duration` | Calculated / Non-additive |
| **E4** | Tăng trưởng cùng kỳ (MoM, YoY) | `Year` $\times$ `Month` | `DimDate` | `Year` $\rightarrow$ `Month` | - `Revenue MoM %`<br>- `Revenue YoY %`<br>- `Trip MoM %`<br>- `Trip YoY %` | Calculated (Time Intelligence / OLAP Lead/Lag) |
| **E5** | Dashboard không gian & thời gian | a. `Zone (LocationID)`<br>b. `Borough` $\times$ `Month` $\times$ `Hour` | - `DimTaxiZone` (GIS)<br>- `DimDate`<br>- `DimTime` | - GIS: `City` $\rightarrow$ `Borough` $\rightarrow$ `Zone`<br>- Thời gian: `Month` $\rightarrow$ `Daypart` $\rightarrow$ `Hour` | - `Pickup Trips`<br>- `Drop-off Trips`<br>- `Hourly Revenue`<br>- `Trip Intensity` | Additive |

---

## 3. Chi tiết Cây Phân cấp (Hierarchies) trong Mô hình

### 3.1. Phân cấp Thời gian (Temporal Hierarchies)
Mô hình hỗ trợ hai luồng phân cấp thời gian riêng biệt:
1. **Lịch ngày (Calendar Hierarchy):**
   $$\text{Calendar Year} \longrightarrow \text{Calendar Quarter} \longrightarrow \text{Calendar Month} \longrightarrow \text{Calendar Day}$$
   - Thuộc tính phụ trợ: `Day of Week` (Monday, Tuesday...), `Is Weekend` (True/False), `Day of Month` (1–31).
2. **Khung giờ trong ngày (Time-of-Day Hierarchy):**
   $$\text{Daypart (Sáng, Trưa, Chiều, Tối, Đêm)} \longrightarrow \text{Hour of Day (0–23)} \longrightarrow \text{Minute (0–59)}$$

### 3.2. Phân cấp Địa lý (Geographic Hierarchy)
$$\text{City (NYC)} \longrightarrow \text{Borough (Manhattan, Queens, Brooklyn, Bronx, Staten Island, EWR)} \longrightarrow \text{Taxi Zone (265 zones)} \longrightarrow \text{LocationID (1–265)}$$
- Thuộc tính phân nhóm dịch vụ: `service_zone` (Yellow Zone, Boro Zone, EWR, Airports, N/A).
- Lưu ý: Cần hỗ trợ phân cấp độc lập cho **Điểm đón (Pickup)** và **Điểm trả (Drop-off)** thông qua cơ chế Role-playing Dimension.

### 3.3. Phân cấp Phân khúc Khách hàng & Hành trình
- **Quy mô nhóm khách (Passenger Grouping):**
  $$\text{All Trips} \longrightarrow \text{Solo Rider (1)} \;|\; \text{Small Group (2–4)} \;|\; \text{Large Group (5+)} \;|\; \text{Unknown/Zero}$$
- **Cự ly di chuyển (Distance Banding):**
  $$\text{All Trips} \longrightarrow \text{Very Short } (\le 1 \text{ mi}) \longrightarrow \text{Short } (1 - 3 \text{ mi}) \longrightarrow \text{Medium } (3 - 5 \text{ mi}) \longrightarrow \text{Long } (5 - 10 \text{ mi}) \longrightarrow \text{Very Long } (> 10 \text{ mi})$$
- **Biểu phí cước (Rate Code):**
  $$\text{Rate Code Group (Standard vs Special/Airport/Negotiated)} \longrightarrow \text{Rate Code Description} \longrightarrow \text{RatecodeID (1..6, 99)}$$

---

## 4. Bảng Phân loại Thước đo (Measure Classification Matrix)

| Tên Measure trong Fact | Tên hiển thị | Tính chất (Additivity) | Hàm tổng hợp cơ sở (Base Aggregation) | Công thức tầng OLAP / Dashboard |
|---|---|---|---|---|
| `trip_record_count` | Số chuyến | Fully Additive | `COUNT(1)` | `SUM(trip_record_count)` |
| `passenger_count` | Số hành khách | Fully Additive | `SUM(passenger_count)` | `SUM(passenger_count)` |
| `trip_distance` | Cự ly di chuyển (dặm) | Fully Additive | `SUM(trip_distance)` | - Tổng: `SUM(trip_distance)`<br>- Trung bình: `SUM(trip_distance) / COUNT(1)` |
| `fare_amount` | Cước cơ bản ($) | Fully Additive | `SUM(fare_amount)` | `SUM(fare_amount)` |
| `extra` | Phụ phí giờ cao điểm ($) | Fully Additive | `SUM(extra)` | `SUM(extra)` |
| `mta_tax` | Thuế MTA ($) | Fully Additive | `SUM(mta_tax)` | `SUM(mta_tax)` |
| `tip_amount` | Tiền boa qua thẻ ($) | Fully Additive | `SUM(tip_amount)` | `SUM(tip_amount)` |
| `tolls_amount` | Phí cầu đường ($) | Fully Additive | `SUM(tolls_amount)` | `SUM(tolls_amount)` |
| `improvement_surcharge`| Phụ phí nâng cấp ($) | Fully Additive | `SUM(improvement_surcharge)` | `SUM(improvement_surcharge)` |
| `congestion_surcharge` | Phụ phí ùn tắc ($) | Fully Additive | `SUM(congestion_surcharge)` | `SUM(congestion_surcharge)` |
| `airport_fee` | Phí đón sân bay ($) | Fully Additive | `SUM(airport_fee)` | `SUM(airport_fee)` |
| `total_amount` | Tổng doanh thu ($) | Fully Additive | `SUM(total_amount)` | `SUM(total_amount)` |
| `trip_duration_seconds` | Thời gian chuyến đi | Fully Additive (thời lượng) | `SUM(trip_duration_seconds)` | - Phút: `SUM(duration_seconds) / 60`<br>- Trung bình: `SUM(duration_seconds) / COUNT(1) / 60` |
| `calculated_speed_mph` | Vận tốc trung bình | Non-Additive | Không được SUM | `SUM(trip_distance) / (SUM(duration_seconds) / 3600)` |
| `tip_ratio` | Tỷ lệ tip trung bình | Non-Additive | Không được SUM | `SUM(tip_amount) / SUM(fare_amount)` (lọc thẻ tín dụng) |
| `revenue_per_trip` | Doanh thu / chuyến | Non-Additive | Không được SUM | `SUM(total_amount) / COUNT(1)` |
