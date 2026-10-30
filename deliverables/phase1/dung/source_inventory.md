# Data Source Inventory & Limitations (Phase 1)

**Tác giả:** Dũng  
**Dự án:** NYC Yellow Taxi Business Intelligence & Data Warehouse (Phase 1 - Modeling)  
**Phạm vi dữ liệu:** Tháng 01/2022 đến Tháng 12/2023 (24 tháng)  
**Tài liệu liên quan:** [Phase 1 Overview](plans/phase1/phase1_overview.md), [Dũng's Plan](plans/phase1/phase1_dung.md), [Lộc's Plan](plans/phase1/phase1_loc.md)

---

## 1. Tổng quan & Phạm vi kiểm kê (Executive Summary)

Tài liệu này thực hiện **Gói công việc A (Inventory the selected data)** theo kế hoạch của Dũng, cung cấp thông tin kiểm kê toàn diện về các tệp dữ liệu nguồn, định dạng, độ bao phủ, ngữ nghĩa và các giới hạn kỹ thuật.

### Xác nhận phạm vi dữ liệu (Coverage Scope Caveat):
* **Mô tả đề bài:** Đề bài tổng thể mô tả dữ liệu NYC Yellow Taxi trong giai đoạn 2009–2026.
* **Phạm vi được chọn của nhóm:** Mẫu dữ liệu chính thức được thống nhất chọn cho Phase 1 (và toàn bộ dự án) là **24 tháng liên tục từ 01/2022 đến 12/2023**.
* **Lưu ý quan trọng:** Toàn bộ quan sát, thống kê mô tả, kiểm tra schema và thiết kế mô hình phải được diễn giải là kết quả của giai đoạn **2022–2023**, không ngụ ý hay ngoại suy cho toàn bộ giai đoạn 2009–2026.

---

## 2. Danh mục các nguồn dữ liệu được chọn (Selected Source Inventory)

### 2.1. Dữ liệu chuyến đi: 24 tệp Parquet Yellow Taxi (`dataset/trip_data/`)

Dữ liệu chuyến đi chính thức được cung cấp bởi Ủy ban Taxi và Xe cho thuê Thành phố New York (NYC TLC), lưu trữ định dạng **Apache Parquet**. Tổng dung lượng danh định của 24 tệp là **1,250,843,281 bytes (~1.16 GB)**.

* **Nguồn công bố:** [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
* **URL CloudFront:** `https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_YYYY-MM.parquet`

| STT | Tên tệp | Kỳ dữ liệu | Định dạng | Nguồn tải |
|:---:|:---|:---:|:---:|:---|
| 1 | `yellow_tripdata_2022-01.parquet` | 01/2022 | Parquet | NYC TLC / Cloudfront |
| 2 | `yellow_tripdata_2022-02.parquet` | 02/2022 | Parquet | NYC TLC / Cloudfront |
| 3 | `yellow_tripdata_2022-03.parquet` | 03/2022 | Parquet | NYC TLC / Cloudfront |
| 4 | `yellow_tripdata_2022-04.parquet` | 04/2022 | Parquet | NYC TLC / Cloudfront |
| 5 | `yellow_tripdata_2022-05.parquet` | 05/2022 | Parquet | NYC TLC / Cloudfront |
| 6 | `yellow_tripdata_2022-06.parquet` | 06/2022 | Parquet | NYC TLC / Cloudfront |
| 7 | `yellow_tripdata_2022-07.parquet` | 07/2022 | Parquet | NYC TLC / Cloudfront |
| 8 | `yellow_tripdata_2022-08.parquet` | 08/2022 | Parquet | NYC TLC / Cloudfront |
| 9 | `yellow_tripdata_2022-09.parquet` | 09/2022 | Parquet | NYC TLC / Cloudfront |
| 10 | `yellow_tripdata_2022-10.parquet` | 10/2022 | Parquet | NYC TLC / Cloudfront |
| 11 | `yellow_tripdata_2022-11.parquet` | 11/2022 | Parquet | NYC TLC / Cloudfront |
| 12 | `yellow_tripdata_2022-12.parquet` | 12/2022 | Parquet | NYC TLC / Cloudfront |
| 13 | `yellow_tripdata_2023-01.parquet` | 01/2023 | Parquet | NYC TLC / Cloudfront |
| 14 | `yellow_tripdata_2023-02.parquet` | 02/2023 | Parquet | NYC TLC / Cloudfront |
| 15 | `yellow_tripdata_2023-03.parquet` | 03/2023 | Parquet | NYC TLC / Cloudfront |
| 16 | `yellow_tripdata_2023-04.parquet` | 04/2023 | Parquet | NYC TLC / Cloudfront |
| 17 | `yellow_tripdata_2023-05.parquet` | 05/2023 | Parquet | NYC TLC / Cloudfront |
| 18 | `yellow_tripdata_2023-06.parquet` | 06/2023 | Parquet | NYC TLC / Cloudfront |
| 19 | `yellow_tripdata_2023-07.parquet` | 07/2023 | Parquet | NYC TLC / Cloudfront |
| 20 | `yellow_tripdata_2023-08.parquet` | 08/2023 | Parquet | NYC TLC / Cloudfront |
| 21 | `yellow_tripdata_2023-09.parquet` | 09/2023 | Parquet | NYC TLC / Cloudfront |
| 22 | `yellow_tripdata_2023-10.parquet` | 10/2023 | Parquet | NYC TLC / Cloudfront |
| 23 | `yellow_tripdata_2023-11.parquet` | 11/2023 | Parquet | NYC TLC / Cloudfront |
| 24 | `yellow_tripdata_2023-12.parquet` | 12/2023 | Parquet | NYC TLC / Cloudfront |

### 2.2. Dữ liệu tham chiếu không gian / địa lý (Taxi Zone Assets)

1. **Tệp bảng tra cứu (`taxi+_zone_lookup.csv`):**
   * **Dung lượng:** 12,331 bytes.
   * **Cấu trúc:** Gồm 265 dòng dữ liệu duy nhất tương ứng với các `LocationID` từ 1 đến 265.
   * **Các trường:** `LocationID` (int), `Borough` (string), `Zone` (string), `service_zone` (string).
2. **Bộ Shapefile (`taxi_zones/`):**
   * Bao gồm 5 tệp thành phần chuẩn ESRI:
     * `taxi_zones.shp` (1,586,264 bytes): Chứa dữ liệu hình học (polygons).
     * `taxi_zones.dbf` (59,927 bytes): Chứa thuộc tính không gian.
     * `taxi_zones.shx` (2,204 bytes): Chỉ mục hình học.
     * `taxi_zones.prj` (565 bytes): Hệ quy chiếu tọa độ `NAD_1983_StatePlane_New_York_Long_Island_FIPS_3104_Feet` (EPSG:2263).
     * `taxi_zones.cpg` (5 bytes): Bộ mã ký tự (UTF-8).
   * **Số lượng hình học:** Shapefile chỉ chứa **263 polygons** (tương ứng với LocationID từ 1 đến 263).

---

## 3. Quy ước và Xử lý các trường hợp đặc biệt về Địa lý

Căn cứ vào so sánh giữa `taxi+_zone_lookup.csv` và `taxi_zones.shp`:
* **LocationID 1 – 263:** Có đầy đủ thông tin tên Borough, Zone, Service Zone và có Polygon hình học tương ứng trên bản đồ.
* **LocationID 264:** Giá trị `Borough = "Unknown"`, `Zone = "N/A"`, `service_zone = "N/A"`. **Không có polygon** trong Shapefile.
* **LocationID 265:** Giá trị `Borough = "N/A"`, `Zone = "Outside of NYC"`, `service_zone = "N/A"`. **Không có polygon** trong Shapefile.

### Quyết định mô hình hóa cho Lộc & Trực:
* Giữ nguyên LocationID 264 và 265 trong chiều `DimTaxiZone` ở mức logic và vật lý để đảm bảo tính toàn vẹn tham chiếu (referential integrity) khi các chuyến đi có mã đón/trả thuộc 264 hoặc 265.
* **Tuyệt đối không tự ý bịa đặt (fabricate) hoặc vẽ thêm polygon** cho 264 và 265.
* Phân biệt rõ giữa **ID 264/265 hợp lệ từ bảng tra cứu** với các giá trị **NULL** hoặc **LocationID không hợp lệ** (ví dụ ID âm hoặc ID > 265 nếu xuất hiện trong dữ liệu thực tế).

---

## 4. Các trường dữ liệu nguồn quan sát trong Parquet (2022–2023)

Cấu trúc 19 cột cơ bản của tệp Yellow Taxi Parquet trong giai đoạn 2022–2023:

| Tên trường nguồn | Kiểu dữ liệu Parquet | Ý nghĩa nghiệp vụ | Ghi chú & Phân loại |
|:---|:---|:---|:---|
| `VendorID` | INT64 / INT32 | Mã nhà cung cấp dịch vụ công nghệ | Raw code (1, 2). Cần đối chiếu từ điển TLC |
| `tpep_pickup_datetime` | TIMESTAMP (us/ns) | Mốc thời gian bắt đầu cuốc xe | Dùng cho Role Pickup Date & Time |
| `tpep_dropoff_datetime` | TIMESTAMP (us/ns) | Mốc thời gian kết thúc cuốc xe | Dùng cho Role Dropoff Date & Time, tính thời lượng |
| `passenger_count` | INT64 / DOUBLE | Số lượng hành khách | **Do tài xế nhập tay** trên đồng hồ |
| `trip_distance` | DOUBLE | Quãng đường chuyến đi | Đơn vị: **Dặm (miles)** đo bởi taximeter |
| `RatecodeID` | INT64 / DOUBLE | Loại biểu giá áp dụng | Raw code (1: Standard, 2: JFK, 3: Newark, ...) |
| `store_and_fwd_flag` | STRING | Cờ lưu trữ tạm trước khi truyền | Y = Store & forward, N = Not |
| `PULocationID` | INT64 | TLC Taxi Zone nơi đón khách | Khóa ngoại tham chiếu `DimTaxiZone` (Pickup Role) |
| `DOLocationID` | INT64 | TLC Taxi Zone nơi trả khách | Khóa ngoại tham chiếu `DimTaxiZone` (Dropoff Role) |
| `payment_type` | INT64 | Hình thức thanh toán | Raw code (1: Credit, 2: Cash, 3: No charge, ...) |
| `fare_amount` | DOUBLE | Tiền cước tính theo đồng hồ | Đơn vị: USD |
| `extra` | DOUBLE | Phụ phí giờ cao điểm / ban đêm | $0.50, $1.00, v.v. |
| `mta_tax` | DOUBLE | Thuế MTA | Cố định thông thường $0.50 |
| `tip_amount` | DOUBLE | Tiền tip | **Chỉ tính tip qua thẻ**, không có tip tiền mặt |
| `tolls_amount` | DOUBLE | Tiền phí cầu đường | Đơn vị: USD |
| `improvement_surcharge`| DOUBLE | Phụ phí cải thiện phương tiện | Cố định $0.30 (bắt đầu từ 2015) |
| `total_amount` | DOUBLE | Tổng tiền thanh toán cho cuốc xe | Đã bao gồm các loại thuế, phí và tip ghi nhận |
| `congestion_surcharge` | DOUBLE | Phụ phí chống ùn tắc NYS | Phụ phí khu vực Nam đường 96th Manhattan ($2.50) |
| `airport_fee` | DOUBLE | Phí sân phục vụ sân bay | $1.25 tại LaGuardia & JFK |

---

## 5. Ngữ nghĩa và Giới hạn dữ liệu nguồn (Source Semantics & Limitations)

Dành cho **Lộc (thiết kế Fact & Grain)**, **Phúc (xác định Metric)** và **Trực (đặc tả Physical Spec)**:

1. **Không có khóa định danh chuyến đi duy nhất (No Unique Trip ID):**
   * Dữ liệu nguồn TLC Yellow Taxi **không cung cấp** cột `trip_id` hay bất kỳ định danh duy nhất ổn định nào cho từng chuyến đi.
   * **Quy ước Grain:** Hạt dữ liệu của Fact được định nghĩa chính xác là **"Một dòng bản ghi chuyến đi từ nguồn" (one row per Yellow Taxi source record)**, không được tự ý gọi là "chuyến đi duy nhất được đảm bảo" (guaranteed unique trip).
2. **Số lượng hành khách (`passenger_count`):**
   * Đây là trường do tài xế nhập thủ công vào màn hình đồng hồ tính cước. Có thể xuất hiện giá trị 0 hoặc số lượng rất lớn/bất thường. Không đại diện cho số người đi xe duy nhất được kiểm chứng độc lập.
3. **Quãng đường di chuyển (`trip_distance`):**
   * Tính theo đơn vị **dặm (miles)** ghi nhận từ đồng hồ đo. Cần lưu ý các trường hợp quãng đường bằng 0 hoặc cực lớn khi thời lượng ngắn.
4. **Giới hạn về Tiền Tip (`tip_amount`):**
   * Theo đúng định nghĩa của TLC, trường `tip_amount` **chỉ tự động ghi nhận tiền tip qua thẻ tín dụng (Credit Card)**. Các khoản tiền tip bằng tiền mặt không được phản ánh trong hệ thống.
   * Do đó, mọi chỉ số liên quan đến tỷ lệ tip (tip ratio, average tip) phải ghi chú rõ điều kiện giới hạn này.
5. **Tổng tiền (`total_amount`):**
   * Không bao gồm tiền tip trả bằng tiền mặt.
6. **Mã nhà cung cấp (`VendorID`):**
   * Giữ nguyên raw code (1, 2,...). Theo từ điển TLC:
     * 1 = Creative Mobile Technologies, LLC (CMT)
     * 2 = VeriFone Inc. (VTS)
   * Tuyệt đối giữ nguyên mã gốc, không tự suy diễn nếu có sự sai lệch giữa các phiên bản từ điển.

---

## 6. Bàn giao sang Gói tiếp theo (Handoff)

* **Chuyển giao cho Lộc (Gói A & B):** Sử dụng danh mục 24 tệp, cấu trúc 19 cột và các lưu ý về grain / ID để cùng Dũng triển khai chạy code Data Profiling và xây dựng thiết kế bảng `FactYellowTaxiTrip`.
* **Chuyển giao cho Phúc (Gói C):** Đối chiếu danh sách các cột đo lường (`measures`) và các trường phân loại thực tế với ma trận yêu cầu C1–C8, E1–E5.
* **Chuyển giao cho Trực:** Cung cấp thông số kỹ thuật tệp, đường dẫn và các ngoại lệ về địa lý (ID 264/265) phục vụ viết mô tả mô hình và đặc tả vật lý.

