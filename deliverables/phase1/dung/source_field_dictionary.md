# Source Field Dictionary (Phase 1)

**Tác giả:** Dũng  
**Dự án:** NYC Yellow Taxi Business Intelligence & Data Warehouse (Phase 1 - Modeling)  
**Phạm vi:** Dữ liệu TLC Yellow Taxi giai đoạn 2022–2023 & Bảng tra cứu Taxi Zones  
**Tài liệu tham chiếu:** TLC Yellow Taxi Trip Record Data Dictionary, TLC Rate Code & Payment Type Guides  

---

## 1. Giới thiệu

Tài liệu này định nghĩa chi tiết toàn bộ các trường dữ liệu xuất hiện trong 24 tệp Parquet (`yellow_tripdata_2022-*.parquet` và `yellow_tripdata_2023-*.parquet`) cùng các trường trong tệp danh mục tra cứu khu vực (`taxi_zone_lookup.csv`). 

Từ điển này đóng vai trò là cơ sở kỹ thuật nguồn (Source Evidence) để **Lộc** xây dựng bảng `FactYellowTaxiTrip`, đồng thời để **Dũng & Lộc** thiết kế các bảng chiều dữ liệu (`DimTaxiZone`, `DimVendor`, `DimRateCode`, `DimPaymentType`).

---

## 2. Bảng từ điển các trường dữ liệu chuyến đi (Trip Record Fields)

| STT | Tên trường nguồn (Source Field) | Kiểu dữ liệu Parquet | Đơn vị đo | Ý nghĩa nghiệp vụ | Phân loại trong DDS | Mô tả chi tiết & Giới hạn nguồn |
|:---:|:---|:---:|:---:|:---|:---:|:---|
| 1 | `VendorID` | INT64 / INT32 | Mã (Code) | Mã định danh nhà cung cấp công nghệ TPEP | Foreign Key (`DimVendor`) | Mã nhà cung cấp thiết bị tính cước trên xe taxi. Giá trị: `1`, `2`. Có thể xuất hiện giá trị lạ/NULL. |
| 2 | `tpep_pickup_datetime` | TIMESTAMP (us/ns) | Thời gian (UTC/EST) | Thời điểm đồng hồ taxi bắt đầu tính cước | Foreign Key (`DimDate`, `DimTime` - Pickup Role) | Thời điểm bắt đầu cuốc xe. Cần tách thành `PickupDateKey` và `PickupTimeKey`. |
| 3 | `tpep_dropoff_datetime` | TIMESTAMP (us/ns) | Thời gian (UTC/EST) | Thời điểm đồng hồ taxi tắt tính cước | Foreign Key (`DimDate`, `DimTime` - Dropoff Role) | Thời điểm kết thúc cuốc xe. Dùng để tính thời lượng cuốc xe (`duration = dropoff - pickup`). |
| 4 | `passenger_count` | INT64 / DOUBLE | Người | Số lượng hành khách trên xe | Fact Measure / Degenerate | **Do tài xế tự bấm bằng tay (Driver-reported)**. Thường từ 1 đến 6. Có trường hợp bằng 0 hoặc NULL. |
| 5 | `trip_distance` | DOUBLE | Dặm (Miles) | Quãng đường di chuyển của cuốc xe | Fact Measure / Degenerate | Quãng đường đo bởi taximeter tính bằng dặm. Có thể xuất hiện giá trị 0 hoặc ngoại lai cực lớn. |
| 6 | `RatecodeID` | INT64 / DOUBLE | Mã (Code) | Loại biểu phí áp dụng cho cuốc xe cuối chuyến | Foreign Key (`DimRateCode`) | Mã loại biểu giá theo quy định của TLC tại thời điểm kết thúc chuyến xe (1: Chuẩn, 2: JFK, 3: Newark,...). |
| 7 | `store_and_fwd_flag` | STRING | Ký tự (Y/N) | Cờ lưu trữ tạm trước khi truyền về server | Fact Attribute / Flag | `Y`: Bản ghi lưu trên bộ nhớ xe rồi mới gửi; `N`: Bản ghi truyền trực tiếp thời gian thực. |
| 8 | `PULocationID` | INT64 | Mã TLC Zone | Khu vực đón khách (Pickup Taxi Zone ID) | Foreign Key (`DimTaxiZone` - Pickup Role) | Mã định danh khu vực đón khách, tham chiếu đến `LocationID` trong bảng tra cứu (1–265). |
| 9 | `DOLocationID` | INT64 | Mã TLC Zone | Khu vực trả khách (Dropoff Taxi Zone ID) | Foreign Key (`DimTaxiZone` - Dropoff Role) | Mã định danh khu vực trả khách, tham chiếu đến `LocationID` trong bảng tra cứu (1–265). |
| 10 | `payment_type` | INT64 | Mã (Code) | Phương thức hành khách thanh toán | Foreign Key (`DimPaymentType`) | Mã phương thức thanh toán (1: Thẻ, 2: Tiền mặt, 3: Miễn phí, 4: Tranh chấp, 5: Không xác định, 6: Hủy chuyến). |
| 11 | `fare_amount` | DOUBLE | USD ($) | Tiền cước tính theo đồng hồ (Time & Distance) | Fact Measure (Additive) | Cước thuần đo bằng thời gian và khoảng cách theo biểu giá quy định. Có thể có giá trị âm (hoàn tiền/tranh chấp). |
| 12 | `extra` | DOUBLE | USD ($) | Các khoản phụ phí linh hoạt | Fact Measure (Additive) | Bao gồm phụ phí giờ cao điểm buổi chiều ($1.00) và phụ phí ban đêm ($0.50). |
| 13 | `mta_tax` | DOUBLE | USD ($) | Thuế giao thông công cộng đô thị (MTA Tax) | Fact Measure (Additive) | Thuế cố định $0.50 tự động kích hoạt cho các chuyến đi có biểu giá tính thuế. |
| 14 | `tip_amount` | DOUBLE | USD ($) | Tiền tip (tiền boa) cho tài xế | Fact Measure (Additive) | **Chỉ tự động ghi nhận tiền tip qua thẻ tín dụng**. Khách tip bằng tiền mặt không được phản ánh (ghi nhận = 0). |
| 15 | `tolls_amount` | DOUBLE | USD ($) | Tiền phí cầu đường / hầm đường bộ | Fact Measure (Additive) | Tổng số tiền phí cầu đường hành khách chi trả trong suốt chuyến đi. |
| 16 | `improvement_surcharge`| DOUBLE | USD ($) | Phụ phí cải thiện phương tiện taxi | Fact Measure (Additive) | Phụ phí cố định $0.30 áp dụng từ năm 2015 nhằm hỗ trợ chương trình xe lăn và cải tiến đội xe. |
| 17 | `total_amount` | DOUBLE | USD ($) | Tổng số tiền thanh toán của chuyến đi | Fact Measure (Additive) | Tổng tiền thanh toán của hành khách. **Lưu ý: Không bao gồm tiền tip bằng tiền mặt**. |
| 18 | `congestion_surcharge` | DOUBLE | USD ($) | Phụ phí chống ùn tắc bang New York | Fact Measure (Additive) | Phụ phí $2.50 áp dụng cho các cuốc xe đón, trả hoặc đi qua khu vực trung tâm Manhattan (phía Nam đường 96th). |
| 19 | `airport_fee` | DOUBLE | USD ($) | Phí phục vụ sân bay | Fact Measure (Additive) | Phí $1.25 đối với các cuốc xe đón hoặc trả tại sân bay LaGuardia (LGA) và John F. Kennedy (JFK). |

---

## 3. Bảng mã danh mục chuẩn hóa (Domain Code Descriptions)

Nhằm đảm bảo tính chính xác và không tự suy đoán, dưới đây là định nghĩa chuẩn theo tài liệu của Ủy ban NYC TLC áp dụng cho dữ liệu 2022–2023:

### 3.1. Mã nhà cung cấp công nghệ (`VendorID`)

| Mã thô (Raw Code) | Tên nhà cung cấp (TLC Official Name) | Tên viết tắt thông dụng | Ghi chú & Đánh giá |
|:---:|:---|:---:|:---|
| `1` | Creative Mobile Technologies, LLC | CMT | Nhà cung cấp thiết bị công nghệ TPEP trên xe taxi. |
| `2` | VeriFone Inc. | VTS / Curb | Nhà cung cấp thiết bị công nghệ TPEP trên xe taxi. |
| *Khác / NULL* | Unknown Provider | UNKNOWN | Ghi nhận các trường hợp mã lỗi hoặc không xác định từ dữ liệu nguồn. |

> **Lưu ý mô hình hóa:** Giữ nguyên giá trị khóa tự nhiên `VendorID` trong mô hình chiều, không tự ý gộp nhóm nếu không có quy định từ TLC.

---

### 3.2. Mã loại biểu giá (`RatecodeID`)

| Mã thô (Raw Code) | Tên biểu giá chuẩn TLC (Rate Description) | Chi tiết cách áp dụng | Ghi chú mô hình hóa |
|:---:|:---|:---|:---|
| `1` | Standard rate | Biểu cước đồng hồ tiêu chuẩn áp dụng trong nội đô NYC. | Phổ biến nhất (> 90% số chuyến). |
| `2` | JFK | Cước trọn gói cố định giữa Manhattan và Sân bay JFK (Flat fare). | Cước cố định quy định theo mốc thời gian. |
| `3` | Newark | Biểu giá đi đến Sân bay Newark (New Jersey). Tính theo đồng hồ + phụ phí. | Chuyến đi ra ngoài ranh giới thành phố. |
| `4` | Nassau or Westchester | Biểu giá đi các hạt ngoại thành Nassau hoặc Westchester. | Tính theo đồng hồ nội đô + biểu giá ngoài thành phố. |
| `5` | Negotiated fare | Giá cước thỏa thuận trực tiếp giữa tài xế và hành khách. | Không bắt buộc theo đồng hồ tiêu chuẩn. |
| `6` | Group ride | Chuyến đi ghép nhóm nhiều hành khách. | Rất hiếm gặp trong dữ liệu hiện đại. |
| `99` / *Khác / NULL* | Unknown / Special | Biểu giá không xác định hoặc lỗi mã hóa trên taximeter. | Gán về bản ghi `RateCodeKey = -1` (Unknown). |

---

### 3.3. Mã phương thức thanh toán (`payment_type`)

| Mã thô (Raw Code) | Phương thức thanh toán (TLC Description) | Đặc tính ghi nhận dữ liệu | Lưu ý quan trọng cho phân tích |
|:---:|:---|:---|:---|
| `1` | Credit card | Thanh toán bằng thẻ ngân hàng qua thiết bị TPEP. | **Có ghi nhận `tip_amount` đầy đủ**. Dùng cho tính Tip Ratio. |
| `2` | Cash | Thanh toán bằng tiền mặt trực tiếp cho tài xế. | **`tip_amount` luôn được ghi nhận là 0.00** trên hệ thống. |
| `3` | No charge | Chuyến xe không tính cước (miễn phí). | Thường có `fare_amount = 0` hoặc các chuyến công vụ. |
| `4` | Dispute | Giao dịch tranh chấp / khiếu nại cước. | Có thể xuất hiện số tiền âm hoặc đảo giao dịch. |
| `5` | Unknown | Phương thức không xác định. | Giá trị không hợp lệ từ nguồn. |
| `6` | Voided trip | Cuốc xe bị hủy sau khi bật đồng hồ. | Cần tách biệt với các chuyến đi thành công thông thường. |
| *Khác / NULL* | Missing / Unknown | Giá trị trống hoặc ngoài danh mục 1–6. | Gán về bản ghi `PaymentTypeKey = -1` (Unknown). |

---

## 4. Từ điển trường dữ liệu địa lý Taxi Zones (`taxi_zone_lookup.csv`)

| Tên trường | Kiểu dữ liệu | Ý nghĩa | Mô tả chi tiết & Giới hạn |
|:---|:---:|:---|:---|
| `LocationID` | INT (1–265) | Khóa định danh vùng taxi (Natural Key) | Khóa tự nhiên duy nhất đại diện cho từng vùng phân vùng giao thông của TLC. |
| `Borough` | STRING | Tên quận thuộc Thành phố New York | Gồm 5 quận chính: `Manhattan`, `Queens`, `Brooklyn`, `Bronx`, `Staten Island`; cộng thêm `EWR` (Newark Airport) và `Unknown`. |
| `Zone` | STRING | Tên khu phố / tiểu vùng chi tiết | Tên địa danh cụ thể (ví dụ: `Times Square/Theatre District`, `JFK Airport`, `Astoria`,...). |
| `service_zone` | STRING | Phân vùng dịch vụ taxi theo quy định TLC | Các giá trị: `Yellow Zone` (chủ yếu Manhattan), `Boro Zone` (các quận ngoài), `Airports` (JFK/LGA), `EWR`, và `N/A`. |

---

## 5. Kết luận & Khuyến nghị kỹ thuật

1. **Khóa logic và Surrogate Keys:** Các bảng Dimension trong kho dữ liệu sẽ sinh khóa thay thế (Surrogate Key kiểu số nguyên dạng `VendorKey`, `RateCodeKey`, `PaymentTypeKey`, `TaxiZoneKey`) và lưu giữ mã nguồn gốc làm Khóa nghiệp vụ tự nhiên (Natural Business Key).
2. **Xử lý giá trị NULL/Dị thường:** Thiết lập bản ghi mặc định `Key = -1` với mô tả `Unknown / Missing` cho tất cả các chiều để đảm bảo tính toàn vẹn khóa ngoại (Referential Integrity) mà không làm mất bản ghi Fact khi nạp dữ liệu.
3. **Phân biệt vai trò đón/trả:** `PULocationID` và `DOLocationID` tham chiếu cùng một chiều `DimTaxiZone` dưới 2 vai trò riêng biệt (Pickup Zone Role và Dropoff Zone Role).
