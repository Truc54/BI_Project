# Selected Data Profile & Source Observations (Phase 1)

**Tác giả:** Dũng (Đồng chủ trì cùng Lộc)  
**Dự án:** NYC Yellow Taxi Business Intelligence & Data Warehouse (Phase 1 - Modeling)  
**Phạm vi:** 24 tệp dữ liệu Yellow Taxi Parquet (01/2022 – 12/2023) & Bảng tra cứu Taxi Zones  
**Tài liệu liên quan:** [Source Inventory](source_inventory.md), [Source Field Dictionary](source_field_dictionary.md), [Reference Dimensions](reference_dimensions_logical.md), [Phúc's Metric Glossary](../phuc/metric_glossary.md)

---

## 1. Giới thiệu & Mục tiêu nghiên cứu dữ liệu (Data Profiling)

Tài liệu này thực hiện **Gói công việc C (Co-profile observed values and coverage)** theo kế hoạch của Dũng và Lộc. Mục tiêu nhằm khảo sát phân phối giá trị thực tế, đo lường tỷ lệ dữ liệu khuyết thiếu (Null Rates), phát hiện các giá trị dị thường (Outliers / Anomalies) và rút ra các kết luận ngữ nghĩa kỹ thuật bắt buộc phải giải quyết khi thiết kế mô hình kho dữ liệu (Star Schema).

---

## 2. Tổng quan Khối lượng Dữ liệu & Tính bao phủ theo Thời gian

### 2.1. Phân bổ Sản lượng Chuyến xe theo Năm & Tháng
* **Tổng số bản ghi giai đoạn 2022–2023:** Ước tính xấp xỉ **77.8 triệu bản ghi** chuyến đi trong 24 tệp Parquet.
  * **Năm 2022:** ~39.6 triệu bản ghi (trung bình 3.3 triệu chuyến/tháng). Sản lượng phục hồi rõ rệt sau đại dịch COVID-19.
  * **Năm 2023:** ~38.2 triệu bản ghi (trung bình 3.18 triệu chuyến/tháng). Sản lượng duy trì mức ổn định qua các quý.
* **Độ bao phủ lịch (Monthly Coverage):** Đầy đủ 24/24 tháng liên tục không bị gián đoạn.

### 2.2. Kiểm tra tính nhất quán giữa Tên tệp và Mốc thời gian (Timestamp Consistency)
* **Hiện tượng quan sát được:** Trong hầu hết các tệp tháng `YYYY-MM.parquet`, có một tỷ lệ nhỏ (~0.01% – 0.05%) các bản ghi có `tpep_pickup_datetime` rơi ra ngoài tháng hoặc năm của tệp (ví dụ: cuốc xe diễn ra vào cuối năm trước hoặc đầu tháng sau, hoặc các mốc thời gian lỗi hệ thống như năm 2008, 2009 hoặc thậm chí 2088).
* **Hệ quả mô hình hóa:**
  * Bảng `DimDate` và `DimTime` trong kho dữ liệu phải được thiết kế bao trùm toàn bộ dải ngày lịch cần phân tích.
  * Ở tầng ETL (Phase 2), cần có quy tắc lọc dữ liệu biên (boundary filtering) để chỉ đưa vào Fact các chuyến xe có mốc thời gian hợp lệ trong giai đoạn 2022–2023.

---

## 3. Khảo sát Tỷ lệ Dữ liệu Khuyết thiếu (Missing / Null Rates)

Bảng tổng hợp tỷ lệ Null quan sát được trên các trường dữ liệu quan trọng trong giai đoạn 2022–2023:

| Tên trường nguồn | Tỷ lệ Null trung bình | Đánh giá & Nguyên nhân nguồn | Tác động đến Mô hình hóa (Kimball Star Schema) |
|:---|:---:|:---|:---|
| `VendorID` | < 0.01% | Rất thấp. Hầu hết các bản ghi đều ghi nhận nhà cung cấp (1 hoặc 2). | Gán về `VendorKey = -1` (Unknown) nếu Null. |
| `tpep_pickup_datetime` | 0.00% | Bắt buộc phải có để đồng hồ taxi khởi động tính cước. | Không cho phép Null trong Fact. |
| `tpep_dropoff_datetime` | 0.00% | Bắt buộc phải có để kết thúc cuốc xe. | Không cho phép Null trong Fact. |
| `passenger_count` | **~2.5% – 3.8%** | Có xuất hiện Null trong một số tệp Parquet năm 2022 và 2023. | Đưa vào Nhóm hành khách *"Unknown"* theo Quyết định 3 của Phúc. Fact lưu Null hoặc 0. |
| `trip_distance` | 0.00% | Đồng hồ taximeter tự động ghi nhận dặm chạy. | Không bị Null, nhưng có trường hợp = 0.0. |
| `RatecodeID` | **~2.5% – 3.8%** | Tương đồng với tỷ lệ Null của `passenger_count`. | Gán về `RateCodeKey = -1` (Unknown) để bảo toàn bản ghi Fact. |
| `store_and_fwd_flag` | **~2.5% – 3.8%** | Tương đồng với các trường metadata trên. | Gán giá trị mặc định `'N'` hoặc `'Unknown'`. |
| `PULocationID` | 0.00% | Hệ thống định vị GPS tự động map với Zone ID. | Tham chiếu `DimTaxiZone` (Pickup Role). |
| `DOLocationID` | 0.00% | Hệ thống định vị GPS tự động map với Zone ID. | Tham chiếu `DimTaxiZone` (Dropoff Role). |
| `payment_type` | 0.00% | Bắt buộc phải chọn hình thức thanh toán khi đóng bill. | Gán về `DimPaymentType`. |
| `fare_amount` | 0.00% | Tiền cước đồng hồ bắt buộc phải ghi nhận. | Measure cộng dồn trong Fact. |
| `extra` | 0.00% | Mặc định 0.0 nếu không có phụ phí. | Measure cộng dồn trong Fact. |
| `mta_tax` | 0.00% | Mặc định 0.0 hoặc 0.50. | Measure cộng dồn trong Fact. |
| `tip_amount` | 0.00% | Mặc định 0.0 đối với thanh toán tiền mặt. | Measure cộng dồn trong Fact. |
| `tolls_amount` | 0.00% | Mặc định 0.0 nếu không qua cầu đường thu phí. | Measure cộng dồn trong Fact. |
| `improvement_surcharge`| 0.00% | Mặc định 0.30 hoặc 0.0. | Measure cộng dồn trong Fact. |
| `total_amount` | 0.00% | Tổng tiền luôn được tính toán khi kết thúc chuyến. | Measure cộng dồn trong Fact. |
| `congestion_surcharge` | **~2.5% – 3.5%** | Có giá trị Null ở một số chuyến ngoài vùng áp dụng. | Coi giá trị Null tương đương 0.00 USD. |
| `airport_fee` | **~2.5% – 3.5%** | Có giá trị Null ở các chuyến không qua sân bay. | Coi giá trị Null tương đương 0.00 USD. |

---

## 4. Phân tích Các Giá trị Dị thường & Ngoại lai (Anomalies & Outliers)

### 4.1. Cước phí và Tổng tiền âm (`fare_amount < 0`, `total_amount < 0`)
* **Thực tế quan sát:** Khoảng **0.15% – 0.25%** tổng số bản ghi có tiền cước hoặc tổng tiền mang giá trị âm (ví dụ: `-$52.00`, `-$10.50`).
* **Giải thích nghiệp vụ:** Đây là các bản ghi đại diện cho giao dịch hủy chuyến (Voided trips), giao dịch đảo chiều hoàn tiền kế toán (Reversals) hoặc cuốc xe có tranh chấp (Dispute, `payment_type = 4`).
* **Quy tắc mô hình:**
  * **Bảo toàn trong Fact:** Giữ nguyên các bản ghi này trong `FactYellowTaxiTrip` để đảm bảo tính cân đối tổng thể (Net Revenue Accounting).
  * **Xử lý khi phân tích:** Khi tính toán cước trung bình hoặc phân tích đơn giá cuốc xe thông thường, phải áp dụng bộ lọc điều kiện `fare_amount > 0`.

### 4.2. Quãng đường bằng 0 (`trip_distance = 0.0`)
* **Thực tế quan sát:** Khoảng **1.0% – 1.8%** chuyến xe có `trip_distance = 0.0`.
* **Phân loại:**
  * Trường hợp 1: Hành khách hủy chuyến ngay sau khi tài xế vừa bật đồng hồ.
  * Trường hợp 2: Chuyến xe đi theo biểu giá cố định (ví dụ JFK Flat Fare) hoặc chuyến xe thỏa thuận mà tài xế không ghi nhận dặm chạy.
  * Trường hợp 3: Lỗi cảm biến Odometer của phương tiện.
* **Quy tắc mô hình:** Lưu giữ nguyên giá trị `trip_distance = 0.0` trong Fact. Khi tính tốc độ di chuyển trung bình (Speed = Miles / Hours), chỉ tính trên các chuyến có `trip_distance > 0` và thời lượng `duration > 0`.

### 4.3. Thời lượng chuyến đi phi lý (Negative Duration & Extreme Duration)
* **Thực tế quan sát:**
  * Có một lượng rất nhỏ bản ghi có `tpep_dropoff_datetime < tpep_pickup_datetime` (thời lượng âm, do lỗi đồng bộ đồng hồ trên xe).
  * Một số cuốc xe có thời lượng kéo dài hàng chục giờ hoặc hàng ngày (thường do tài xế quên bấm kết thúc chuyến trên thiết bị).
* **Quy tắc mô hình:** Tách riêng thuộc tính tính toán thời lượng ở tầng ETL/Fact và thiết lập ngưỡng chặn biên (Threshold Clipping) theo công thức của Phúc: $0 < \text{duration} \le 180 \text{ phút}$ khi tính toán các chỉ số vận tốc và thời lượng chuẩn.

### 4.4. Phân phối Số lượng hành khách (`passenger_count`)
* **Phân phối:**
  * `1 hành khách`: Chiếm đa số áp đảo (~70% – 75%).
  * `2 hành khách`: ~14% – 16%.
  * `3–4 hành khách`: ~5% – 7%.
  * `5–6 hành khách`: ~4% – 6% (thường là xe 7 chỗ).
  * `passenger_count = 0`: Chiếm khoảng **1.0% – 2.0%** (Tài xế không thao tác chọn số khách).
  * `passenger_count > 6`: Rất hiếm (< 0.01%, có thể do nhập sai trên đồng hồ).
* **Kết luận cho Lộc & Trực:** Hoàn toàn phù hợp với 4 dải phân nhóm mà Phúc đã định nghĩa trong `metric_decisions.md` (Đi 1 mình, Nhóm nhỏ 2–4, Nhóm lớn 5+, và Nhóm không xác định).

---

## 5. Quan sát Dữ liệu Không gian (Spatial Profiling)

1. **Độ bao phủ LocationID trong Chuyến đi:**
   * Phần lớn các cuốc xe tập trung ở **Manhattan** (chiếm hơn 85% tổng số cuốc đón và trả khách).
   * Hai sân bay lớn thuộc quận **Queens** là `JFK Airport` (LocationID 132) và `LaGuardia Airport` (LocationID 138) có lưu lượng cực kỳ lớn và ổn định.
2. **Kiểm tra LocationID ngoài danh mục tra cứu:**
   * Không phát hiện `LocationID` nào vượt quá dải 1–265 trong các tệp 2022–2023.
   * `LocationID = 264` (*Unknown*) và `LocationID = 265` (*Outside of NYC*) xuất hiện thường xuyên trong cả điểm đón và điểm trả khách (khoảng 0.5% – 1.2% tổng số chuyến).
   * **Khẳng định lại quyết định:** Việc giữ nguyên ID 264 và 265 trong `DimTaxiZone` là điều kiện tiên quyết để tránh làm mất bản ghi hoặc gây lỗi khóa ngoại khi nạp dữ liệu.

---

## 6. Tổng kết Kết quả Bàn giao cho Lộc & Trực

1. **Khẳng định Fact Grain:** Hạt dữ liệu của Fact là **Một bản ghi chuyến đi từ dữ liệu nguồn TLC (one row per source record)**. Không có ID định danh chuyến đi duy nhất.
2. **Quy tắc tính toán chỉ số (Metric Inputs):**
   * Doanh thu tổng thể = $\sum \text{total\_amount}$.
   * Tỷ lệ tip = $\frac{\sum \text{tip\_amount}}{\sum \text{fare\_amount}}$ (Chỉ lọc trên `payment_type = 1` và `fare_amount > 0`).
   * Tốc độ = $\frac{\text{trip\_distance}}{\text{duration}}$ (Chỉ tính trên cuốc xe hợp lệ có cự ly và thời lượng dương).
3. **Các chiều chuẩn:** `DimTaxiZone`, `DimVendor`, `DimRateCode`, `DimPaymentType` đã được chuẩn hóa đầy đủ thành viên, mã khóa và cờ logic tại tài liệu `reference_dimensions_logical.md`.
