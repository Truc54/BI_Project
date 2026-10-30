# Logical Reference Dimensions Specification (Phase 1)

**Tác giả:** Dũng (Đồng chủ trì cùng Lộc)  
**Dự án:** NYC Yellow Taxi Business Intelligence & Data Warehouse (Phase 1 - Modeling)  
**Tài liệu liên quan:** [Source Field Dictionary](source_field_dictionary.md), [Source Inventory](source_inventory.md), [Phúc's Metric Glossary](../phuc/metric_glossary.md)

---

## 1. Mục đích và Phạm vi thiết kế

Tài liệu này đặc tả thiết kế mức logic (Logical Design) cho 4 bảng chiều dữ liệu cốt lõi có nguồn gốc trực tiếp từ dữ liệu giao dịch và dữ liệu tham chiếu của NYC Taxi and Limousine Commission (TLC):
1. **`DimTaxiZone`** (Chiều Vùng Không gian / Địa lý Taxi)
2. **`DimVendor`** (Chiều Nhà cung cấp dịch vụ công nghệ TPEP)
3. **`DimRateCode`** (Chiều Loại biểu giá cước)
4. **`DimPaymentType`** (Chiều Phương thức thanh toán)

Thiết kế này tuân thủ phương pháp luận Kimball Star Schema, thiết lập các khóa thay thế (Surrogate Keys), bảo toàn khóa nghiệp vụ tự nhiên (Natural Business Keys), định nghĩa rõ ràng các hệ thống phân cấp (Hierarchies) và quy tắc xử lý ngoại lệ (Unknown/Missing Members) cho dữ liệu giai đoạn 2022–2023.

---

## 2. Chiều Địa lý Taxi Zone (`DimTaxiZone`)

### 2.1. Mục đích nghiệp vụ
Phục vụ toàn bộ các phân tích không gian và địa lý (Spatial Analysis), bao gồm:
* Thống kê sản lượng cuốc xe và doanh thu theo Quận (`Borough`) và Tiểu vùng (`Zone`) (Yêu cầu C2, C6).
* Phân tích các cặp tuyến đường phổ biến nhất (Top N Popular Routes) thông qua việc kết nối có thứ tự giữa điểm đón và điểm trả (Yêu cầu C7).
* Phân tích xu hướng biến động theo vùng dịch vụ (`service_zone`) (Yêu cầu E5).

### 2.2. Thiết kế Cấu trúc Logic

| Tên thuộc tính logic | Tên cột logic | Kiểu dữ liệu | Vai trò / Ràng buộc | Định nghĩa nghiệp vụ & Quy tắc chuẩn hóa |
|:---|:---|:---:|:---:|:---|
| **Taxi Zone Key** | `TaxiZoneKey` | INTEGER | **Primary Key** (Surrogate) | Khóa thay thế duy nhất đại diện cho từng vùng địa lý trong kho dữ liệu (bắt đầu từ 1, -1 cho Unknown). |
| **Location ID** | `LocationID` | INTEGER | **Business Key** (Natural) | Mã định danh khu vực do NYC TLC ban hành (từ 1 đến 265). |
| **Borough Name** | `Borough` | VARCHAR(50) | Attribute / Hierarchy Level | Tên quận thuộc NYC: `Manhattan`, `Queens`, `Brooklyn`, `Bronx`, `Staten Island`, `EWR`, hoặc `Unknown`. |
| **Zone Name** | `Zone` | VARCHAR(100) | Attribute / Hierarchy Level | Tên cụ thể của tiểu vùng/khu phố (ví dụ: `Upper East Side South`, `JFK Airport`). |
| **Service Zone** | `ServiceZone` | VARCHAR(50) | Attribute | Vùng dịch vụ taxi TLC quy định: `Yellow Zone`, `Boro Zone`, `Airports`, `EWR`, `N/A`. |
| **Has Geometry Flag** | `HasGeometry` | BOOLEAN | Metadata Flag | Cờ đánh dấu vùng có polygon hình học trong Shapefile (`TRUE` cho ID 1–263, `FALSE` cho ID 264–265). |

### 2.3. Hệ thống phân cấp (Hierarchy)
$$\text{Borough} \longrightarrow \text{Zone} \longrightarrow \text{LocationID}$$

### 2.4. Quy tắc chuẩn hóa dữ liệu đặc thù & Giới hạn Shapefile
* **Bảo toàn ID 264 và 265:**
  * `LocationID = 264`: `Borough = 'Unknown'`, `Zone = 'Unknown / N/A'`, `ServiceZone = 'N/A'`, `HasGeometry = FALSE`.
  * `LocationID = 265`: `Borough = 'Outside NYC'`, `Zone = 'Outside of NYC'`, `ServiceZone = 'N/A'`, `HasGeometry = FALSE`.
  * **Quyết định mô hình:** Tuyệt đối không tự vẽ thêm hoặc phỏng đoán polygon cho 264 và 265. Giữ nguyên để bảo toàn toàn vẹn khóa ngoại từ bảng Fact.
* **Bản ghi mặc định (Missing Member):**
  * `TaxiZoneKey = -1`: Dành cho các cuốc xe có `PULocationID` hoặc `DOLocationID` bị `NULL` hoặc mang giá trị lỗi ngoài dải 1–265.

### 2.5. Cơ chế Role-Playing với Fact
Bảng `DimTaxiZone` đóng 2 vai trò độc lập (Role-Playing Dimension) khi kết nối với `FactYellowTaxiTrip`:
1. **Pickup Taxi Zone Role:** Khóa ngoại `PickupTaxiZoneKey` trong Fact nối với `DimTaxiZone.TaxiZoneKey`.
2. **Dropoff Taxi Zone Role:** Khóa ngoại `DropoffTaxiZoneKey` trong Fact nối với `DimTaxiZone.TaxiZoneKey`.

---

## 3. Chiều Nhà cung cấp dịch vụ công nghệ (`DimVendor`)

### 3.1. Mục đích nghiệp vụ
Hỗ trợ phân tích thị phần, sản lượng chuyến đi và doanh thu cước giữa các đơn vị cung cấp giải pháp công nghệ trên xe taxi (Yêu cầu C2, E2, E3).

### 3.2. Thiết kế Cấu trúc Logic

| Tên thuộc tính logic | Tên cột logic | Kiểu dữ liệu | Vai trò / Ràng buộc | Định nghĩa nghiệp vụ & Quy tắc chuẩn hóa |
|:---|:---|:---:|:---:|:---|
| **Vendor Key** | `VendorKey` | INTEGER | **Primary Key** (Surrogate) | Khóa thay thế duy nhất cho từng nhà cung cấp. |
| **Vendor ID** | `VendorID` | INTEGER | **Business Key** (Natural) | Mã nhà cung cấp thô từ dữ liệu nguồn (1, 2). |
| **Vendor Name** | `VendorName` | VARCHAR(100) | Attribute | Tên pháp nhân đầy đủ theo quy định của TLC. |
| **Vendor Short Name**| `VendorShortName`| VARCHAR(50) | Attribute | Tên viết tắt thông dụng trong ngành: `CMT`, `VeriFone (VTS/Curb)`. |

### 3.3. Dữ liệu thành viên chuẩn (Standard Dimension Members)

| `VendorKey` | `VendorID` | `VendorName` | `VendorShortName` | Ghi chú |
|:---:|:---:|:---|:---|:---|
| `1` | `1` | Creative Mobile Technologies, LLC | CMT | Nhà cung cấp thiết bị công nghệ TPEP. |
| `2` | `2` | VeriFone Inc. | VeriFone / Curb | Nhà cung cấp thiết bị công nghệ TPEP. |
| `-1` | `NULL / Khác` | Unknown / Unassigned Provider | Unknown | Giá trị mặc định khi mã bị thiếu hoặc lỗi. |

---

## 4. Chiều Loại biểu giá (`DimRateCode`)

### 4.1. Mục đích nghiệp vụ
Phân tích cơ cấu chuyến đi theo loại hình dịch vụ (chuẩn nội đô, sân bay JFK/Newark, ngoại thành, đàm phán) và so sánh tỷ lệ tiền tip, cự ly và tốc độ trung bình theo từng loại biểu phí (Yêu cầu C5, E1).

### 4.2. Thiết kế Cấu trúc Logic

| Tên thuộc tính logic | Tên cột logic | Kiểu dữ liệu | Vai trò / Ràng buộc | Định nghĩa nghiệp vụ & Quy tắc chuẩn hóa |
|:---|:---|:---:|:---:|:---|
| **Rate Code Key** | `RateCodeKey` | INTEGER | **Primary Key** (Surrogate) | Khóa thay thế duy nhất cho từng loại biểu giá. |
| **Rate Code ID** | `RatecodeID` | INTEGER | **Business Key** (Natural) | Mã loại biểu giá thô từ dữ liệu nguồn (1, 2, 3, 4, 5, 6, 99). |
| **Rate Description** | `RateDescription`| VARCHAR(100) | Attribute | Tên loại biểu giá theo từ điển chính thức của TLC. |
| **Rate Category** | `RateCategory` | VARCHAR(50) | Attribute | Nhóm phân loại: `Standard`, `Airport`, `Out of Town`, `Negotiated`, `Special`. |
| **Is Flat Fare Flag** | `IsFlatFare` | BOOLEAN | Attribute Flag | Đánh dấu cuốc xe áp dụng giá cước cố định (Ví dụ: JFK flat fare = TRUE). |

### 4.3. Dữ liệu thành viên chuẩn (Standard Dimension Members)

| `RateCodeKey` | `RatecodeID` | `RateDescription` | `RateCategory` | `IsFlatFare` |
|:---:|:---:|:---|:---|:---:|
| `1` | `1` | Standard rate | Standard | FALSE |
| `2` | `2` | JFK | Airport | TRUE |
| `3` | `3` | Newark | Airport | FALSE |
| `4` | `4` | Nassau or Westchester | Out of Town | FALSE |
| `5` | `5` | Negotiated fare | Negotiated | FALSE |
| `6` | `6` | Group ride | Special | FALSE |
| `99` | `99` | Special / Flexible Rate | Special | FALSE |
| `-1` | `Khác / NULL` | Unknown Rate Code | Unknown | FALSE |

---

## 5. Chiều Phương thức thanh toán (`DimPaymentType`)

### 5.1. Mục đích nghiệp vụ
Theo dõi số lượng và tỷ trọng các kênh thanh toán theo khu vực và thời gian (Yêu cầu C3). Quan trọng nhất là phục vụ bài toán **lọc điều kiện chuẩn xác cho tỷ lệ tiền boa (Tip Ratio - Yêu cầu E1)**, đảm bảo chỉ tính tip ratio trên các giao dịch thẻ tín dụng.

### 5.2. Thiết kế Cấu trúc Logic

| Tên thuộc tính logic | Tên cột logic | Kiểu dữ liệu | Vai trò / Ràng buộc | Định nghĩa nghiệp vụ & Quy tắc chuẩn hóa |
|:---|:---|:---:|:---:|:---|
| **Payment Type Key** | `PaymentTypeKey` | INTEGER | **Primary Key** (Surrogate) | Khóa thay thế duy nhất cho từng phương thức thanh toán. |
| **Payment Type ID** | `PaymentTypeID` | INTEGER | **Business Key** (Natural) | Mã phương thức thanh toán thô từ dữ liệu nguồn (1–6). |
| **Payment Description**| `PaymentDescription`| VARCHAR(100) | Attribute | Mô tả chuẩn hóa phương thức thanh toán theo TLC. |
| **Payment Group** | `PaymentGroup` | VARCHAR(50) | Attribute / Hierarchy | Nhóm thanh toán cấp cao: `Electronic`, `Cash`, `Non-Revenue / Exception`. |
| **Allows Electronic Tip**| `AllowsElectronicTip`| BOOLEAN | Analytical Flag | `TRUE` đối với Thẻ tín dụng (`1`), `FALSE` đối với tiền mặt và các loại khác. |

### 5.3. Dữ liệu thành viên chuẩn (Standard Dimension Members)

| `PaymentTypeKey` | `PaymentTypeID` | `PaymentDescription` | `PaymentGroup` | `AllowsElectronicTip` | Ý nghĩa phân tích |
|:---:|:---:|:---|:---|:---:|:---|
| `1` | `1` | Credit card | Electronic | **TRUE** | Kênh thanh toán duy nhất có ghi nhận tiền boa (`tip_amount`). |
| `2` | `2` | Cash | Cash | FALSE | Tiền mặt; tiền boa không được ghi nhận trong hệ thống. |
| `3` | `3` | No charge | Non-Revenue | FALSE | Chuyến đi miễn phí / không thu cước. |
| `4` | `4` | Dispute | Exception | FALSE | Giao dịch tranh chấp hoặc có khiếu nại cước. |
| `5` | `5` | Unknown | Exception | FALSE | Phương thức thanh toán không xác định từ thiết bị. |
| `6` | `6` | Voided trip | Exception | FALSE | Cuốc xe bị hủy sau khi bật đồng hồ tính cước. |
| `-1` | `Khác / NULL` | Missing / Not Specified | Unknown | FALSE | Giá trị rỗng hoặc ngoài danh mục chuẩn. |

---

## 6. Tổng kết Mối quan hệ với Bảng Fact (`FactYellowTaxiTrip`)

```
   +-------------------+              +-------------------------+
   |    DimVendor      |              |   DimTaxiZone (Pickup)  |
   +-------------------+              +-------------------------+
   | PK  VendorKey     |1            1| PK  TaxiZoneKey         |
   +-------------------+              +-------------------------+
             |                                     |
             |           +---------------------+   |
             +---------> | FactYellowTaxiTrip  | <-+ (PickupTaxiZoneKey)
             |           +---------------------+   |
             |           | FK VendorKey        |   |
             |           | FK RateCodeKey      |   |
             |           | FK PaymentTypeKey   |   |
             |           | FK PickupTaxiZoneKey|   |
             |           | FK DropoffTaxiZoneKy| <-+ (DropoffTaxiZoneKey)
             |           | FK PickupDateKey    |   |
             |           | FK DropoffDateKey   |   |
             |           | ... Measures ...    |   |
             |           +---------------------+   |
             |                      |              |
   +-------------------+            | 1            |
   |   DimRateCode     |1           |              |
   +-------------------+------------+              |
   | PK  RateCodeKey   |                           |
   +-------------------+                           |
             |                                     |
   +-------------------+                           |
   |  DimPaymentType   |1                          |
   +-------------------+---------------------------+
   | PK PaymentTypeKey |
   +-------------------+
```

Tài liệu này hoàn tất phần trách nhiệm của **Dũng** về thiết kế các chiều chuẩn tham chiếu và bằng chứng dữ liệu nguồn, làm đầu vào trực tiếp để **Lộc** thiết kế cấu trúc `FactYellowTaxiTrip` và vẽ sơ đồ `dds_logical_model.drawio`.
