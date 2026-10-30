# Metric & Analytical Decisions Log (Phúc - Phase 1)

## 1. Mục đích
Tài liệu này ghi nhận toàn bộ các quyết định nghiệp vụ (Analytical Decisions) và giải pháp chuẩn hóa các điểm còn mơ hồ trong đề bài môn học (**CSC12107 - Đồ án thực hành BI**, FIT-HCMUS) và dữ liệu nguồn TLC Yellow Taxi (2022–2023). 

Mục tiêu là đảm bảo tính nhất quán tuyệt đối về mặt logic tính toán giữa Phúc (Requirements/Metrics), Dũng & Lộc (Profiling/Star Schema) và Trực (Physical DDS & Validation).

---

## 2. Bảng Tổng hợp Quyết định Nghiệp vụ

### Quyết định 1: Định nghĩa Doanh thu (Total Revenue vs. Fare Amount)
- **Vấn đề mơ hồ:** Đề bài yêu cầu phân tích "Doanh thu" (C2, C8, E2, E3, E4). Trong dữ liệu TLC có nhiều cột tiền: `fare_amount`, `extra`, `mta_tax`, `tip_amount`, `tolls_amount`, `improvement_surcharge`, `congestion_surcharge`, `Airport_fee`, và `total_amount`.
- **Quyết định:**
  1. Khi đề cập đến **Tổng doanh thu (Total Revenue)** toàn ngành, sử dụng trường `total_amount`. Đây là số tiền tổng cộng khách hàng chi trả cho dịch vụ taxi.
  2. Bảng Fact `FactYellowTaxiTrip` **bắt buộc phải lưu giữ đầy đủ tất cả các thành phần cước chi tiết** (`fare_amount`, `extra`, `mta_tax`, `tip_amount`, `tolls_amount`, `surcharges`, `airport_fee`).
  3. Để phục vụ bài toán phân rã doanh thu (E2, E3), hệ thống cung cấp thêm chỉ số **Doanh thu cước thuần (Base Fare Revenue)** tính bằng `fare_amount` để đánh giá mức độ cước gốc do chạy theo đồng hồ độc lập với các khoản phụ phí.
- **Cảnh báo dữ liệu nguồn:** TLC quy định `total_amount` không bao gồm tiền boa bằng tiền mặt (cash tip). Điều này phải được ghi chú rõ trong mọi báo cáo doanh thu.

---

### Quyết định 2: Công thức và Điều kiện tính Tỷ lệ tiền boa (Tip Ratio)
- **Vấn đề mơ hồ:** Đề bài yêu cầu: *"So sánh tỷ lệ tiền boa trung bình của từng loại biểu phí chuyến đi"* (E1). Tuy nhiên, không nêu rõ mẫu số là `fare_amount` hay `total_amount`, và có tính các chuyến thanh toán tiền mặt hay không.
- **Quyết định:**
  1. **Mẫu số chuẩn:** Sử dụng `fare_amount` làm mẫu số chuẩn trong ngành vận tải:
     $$\text{Tip Ratio} = \frac{\text{tip\_amount}}{\text{fare\_amount}}$$
     *(Lý do: Khách hàng tip dựa trên giá cước dịch vụ thuần, không ai tip trên khoản thuế MTA, phí cầu đường hay phí ùn tắc).*
  2. **Bộ lọc điều kiện bắt buộc (Filter Scope):**
     - **Chỉ tính trên các giao dịch thanh toán bằng thẻ (`payment_type = 1` - Credit Card).** Tuyệt đối không đưa các giao dịch tiền mặt (`payment_type = 2`) vào mẫu số, vì hệ thống ghi nhận `tip_amount = 0` cho tiền mặt, sẽ làm sai lệch nghiêm trọng tỷ lệ boa thực tế.
     - Điều kiện cước: `fare_amount > 0` (loại bỏ trường hợp cước bằng 0 hoặc âm để tránh chia cho 0).
  3. **Phương pháp tổng hợp:** Báo cáo sẽ hiển thị chỉ số tỷ lệ tip tổng thể có trọng số (Weighted Macro Tip Ratio) cho từng biểu phí:
     $$\text{Macro Tip Ratio} = \frac{\sum_{\text{Credit Card}} \text{tip\_amount}}{\sum_{\text{Credit Card}} \text{fare\_amount}}$$

---

### Quyết định 3: Chuẩn hóa Phân nhóm Hành khách (Passenger Grouping)
- **Vấn đề mơ hồ:** Đề bài yêu cầu: *"Thống kê số lượng chuyến đi theo nhóm số lượng khách đi (đi 1 mình, nhóm 2-4 người, nhóm từ 5 người trở lên)"* (C5). Dữ liệu thực tế có giá trị `passenger_count = 0` hoặc `NULL` hoặc $> 6$.
- **Quyết định:** Thiết lập thang phân nhóm chuẩn hóa:
  - **Nhóm 1: Đi 1 mình (Solo Rider):** `passenger_count = 1`.
  - **Nhóm 2: Nhóm nhỏ (Small Group):** `passenger_count IN (2, 3, 4)`.
  - **Nhóm 3: Nhóm lớn (Large Group):** `passenger_count >= 5` (thường là xe taxi SUV / Minivan).
  - **Nhóm 4: Không xác định (Unknown / Zero):** `passenger_count = 0` HOẶC `NULL`. *(Dữ liệu TLC có khoảng 1–3% chuyến có passenger_count = 0 do tài xế không bấm số khách; nhóm này được tách riêng để không làm méo mó các phân tích hành vi của 3 nhóm trên).*

---

### Quyết định 4: Chuẩn hóa Dải Cự ly Di chuyển (Distance Bands)
- **Vấn đề mơ hồ:** Đề bài yêu cầu thống kê chuyến đi theo *"cự ly di chuyển"* (C5) nhưng không chỉ rõ các mốc khoảng cách.
- **Quyết định:** Căn cứ theo đặc thù giao thông đô thị New York City (Manhattan cự ly ngắn, di chuyển liên quận hoặc đi sân bay cự ly dài), thiết lập 5 dải cự ly chuẩn:
  1. **Rất ngắn (Very Short / Micro Trips):** $0 \le \text{trip\_distance} \le 1.0 \text{ dặm}$ (Chuyến nội khu, đi bộ nhanh hoặc hủy cuốc giữa chừng).
  2. **Ngắn (Short Trips):** $1.0 < \text{trip\_distance} \le 3.0 \text{ dặm}$ (Chuyến nội quận điển hình, phổ biến nhất ở Manhattan).
  3. **Trung bình (Medium Trips):** $3.0 < \text{trip\_distance} \le 5.0 \text{ dặm}$ (Chuyến xuyên khu vực hoặc kết nối Manhattan - Brooklyn/Queens gần).
  4. **Dài (Long Trips):** $5.0 < \text{trip\_distance} \le 10.0 \text{ dặm}$ (Chuyến liên quận xa).
  5. **Rất dài (Very Long / Airport Trips):** $\text{trip\_distance} > 10.0 \text{ dặm}$ (Chuyến đi sân bay JFK/Newark hoặc vùng ngoại vi).
  - *Lưu ý mô hình:* Cột `trip_distance` thực tế (số thực) vẫn được giữ nguyên trong Fact để tính cự ly trung bình chính xác. Dải cự ly được quản lý qua bảng chiều hoặc cột dẫn xuất.

---

### Quyết định 5: Quy tắc Gán Địa bàn Quận/Khu vực (Borough Attribution)
- **Vấn đề mơ hồ:** Đề bài yêu cầu *"Phân tích doanh thu của mỗi quận/khu vực"* (C2), *"thanh toán theo từng quận/khu vực"* (C3), *"dashboard của từng quận/khu vực"* (C6, E5). Một chuyến xe luôn có điểm đón (Pickup) và điểm trả (Drop-off), có thể nằm ở hai quận khác nhau.
- **Quyết định:**
  1. **Nguyên tắc mặc định:** Nhu cầu di chuyển và doanh thu phát sinh dịch vụ được gán theo **Quận đón khách (Pickup Borough)**. Đây là quy chuẩn chung của ngành vận tải đô thị (đo lường nơi phát sinh nhu cầu gọi xe).
  2. **Hỗ trợ đa vai trò (Role-playing Dimension):** Mô hình DDS phải thiết kế bảng `DimTaxiZone` tham gia vào Fact với 2 vai trò độc lập:
     - `Pickup Taxi Zone` (liên kết qua `PULocationID`)
     - `Drop-off Taxi Zone` (liên kết qua `DOLocationID`)
  3. Đối với yêu cầu C6 và E5 (Lưu lượng đón/trả và Bản đồ không gian), hệ thống sẽ tính riêng:
     - `Pickup Count` dựa trên `PULocationID`
     - `Drop-off Count` dựa trên `DOLocationID`
     - `Net Flow` = `Pickup Count` - `Drop-off Count` (để thấy quận/zone nào là nơi xuất cư ròng hay nhập cư ròng trong từng khung giờ).

---

### Quyết định 6: Tuyến đường phổ biến (Top N Popular Routes)
- **Vấn đề mơ hồ:** Yêu cầu C7: *"Top N tuyến lộ trình phổ biến nhất"*. Tuyến đường tính theo cặp Zone hay cặp Borough? Có phân biệt chiều đi và chiều về không?
- **Quyết định:**
  1. Tuyến đường được định nghĩa là **cặp Taxi Zone có thứ tự**:
     $$\text{Route} = (\text{PULocationID} \longrightarrow \text{DOLocationID})$$
  2. **Phân biệt hướng di chuyển:** Chiều từ $A \rightarrow B$ được xem là một tuyến khác biệt so với $B \rightarrow A$. Ví dụ: Tuyến từ *Upper East Side South $\rightarrow$ Midtown Center* khác với chiều ngược lại vì phản ánh hai luồng nhu cầu khác nhau (đi làm buổi sáng vs về nhà buổi chiều).
  3. Giá trị $N$ được thiết kế tham số hóa linh hoạt (Default $N = 10$).

---

### Quyết định 7: Phương pháp luận Giải thích Doanh thu Tháng 5 vs Tháng 6 (E2)
- **Vấn đề mơ hồ:** Yêu cầu E2 hỏi: *"Doanh thu tháng 5 tăng/giảm so với tháng 6? Vì sao? Giải thích nguyên nhân"*.
- **Quyết định:**
  1. **Phạm vi năm:** Thực hiện phân tích so sánh Tháng 5 vs Tháng 6 riêng biệt cho **cả năm 2022 và năm 2023** để kiểm tra tính nhất quán theo mùa (Seasonality).
  2. **Phương pháp phân rã nội tại (Index Decomposition Analysis):** Dữ liệu đồ án chỉ có dữ liệu chuyến đi taxi, không có dữ liệu thời tiết hay sự kiện ngoại sinh. Do đó, nguyên nhân tăng/giảm bắt buộc phải được giải thích một cách khách quan dựa trên việc phân rã phương trình doanh thu:
     $$\text{Total Revenue} = \text{Trip Count} \times \text{Revenue per Trip}$$
     - Kiểm tra xem biến động là do **Số lượng chuyến (Volume Effect)** hay do **Doanh thu bình quân mỗi chuyến (Price/Fare Effect)**.
     - Nếu do Doanh thu/chuyến: Tiếp tục phân rã thành Cự ly trung bình (`Avg Distance`), Thời gian di chuyển (`Avg Duration`), cơ cấu biểu phí sân bay (`Rate Code Mix`), và sự thay đổi của các khoản phụ phí (`Surcharges / Airport Fee`).

---

### Quyết định 8: Phân rã Động lực tăng Doanh thu/Chuyến (E3)
- **Vấn đề mơ hồ:** Yêu cầu E3: *"Doanh thu tăng nhưng số chuyến gần như không đổi. Yếu tố nào làm doanh thu/chuyến tăng?"*.
- **Quyết định:** Sử dụng công thức phân rã cộng tính cấu phần cước bình quân trên mỗi chuyến:
  $$\frac{\text{Total Revenue}}{\text{Trip Count}} = \frac{\sum \text{fare\_amount}}{\text{Trip Count}} + \frac{\sum \text{tip\_amount}}{\text{Trip Count}} + \frac{\sum \text{tolls\_amount}}{\text{Trip Count}} + \frac{\sum \text{surcharges}}{\text{Trip Count}} + \frac{\sum \text{airport\_fee}}{\text{Trip Count}}$$
  Hệ thống sẽ tính toán tốc độ tăng trưởng của từng thành phần để chỉ ra thành phần nào có đóng góp phần trăm lớn nhất vào mức tăng trưởng cước bình quân.

---

### Quyết định 9: Chuẩn hóa Nhà cung cấp Công nghệ (VendorID vs CMT / VTS)
- **Vấn đề mơ hồ:** Đề bài ghi: *"từng nhà cung cấp (CMT, VTS)"* (C2). Trong từ điển dữ liệu TLC:
  - Mã 1: Creative Mobile Technologies, LLC (CMT)
  - Mã 2: VeriFone Inc. (VTS)
- **Quyết định:**
  1. Bảng chiều `DimVendor` sẽ ánh xạ:
     - `VendorID = 1` $\rightarrow$ `Vendor Name = 'Creative Mobile Technologies, LLC'`, `Vendor Abbr = 'CMT'`
     - `VendorID = 2` $\rightarrow$ `Vendor Name = 'VeriFone Inc.'`, `Vendor Abbr = 'VTS'`
     - Các mã khác (nếu xuất hiện trong dữ liệu 2022-2023 như 6 hoặc NULL) $\rightarrow$ `Unknown / Other`.
  2. Giữ nguyên mã số gốc `VendorID` trong Fact và Dimension để đảm bảo toàn vẹn dữ liệu.

---

### Quyết định 10: Xử lý hai mã Zone đặc biệt 264 và 265
- **Vấn đề:** Trong `taxi+_zone_lookup.csv`:
  - `LocationID = 264`: Borough = `Unknown`, Zone = `N/A`, service_zone = `N/A`
  - `LocationID = 265`: Borough = `N/A`, Zone = `Outside of NYC`, service_zone = `N/A`
  File Shapefile ranh giới địa lý chỉ có 263 polygon (LocationID 1–263).
- **Quyết định:**
  1. Giữ nguyên 264 và 265 trong bảng chiều `DimTaxiZone` để các chuyến đón/trả tại vùng này không bị rớt dữ liệu (không vi phạm toàn vẹn khóa ngoại).
  2. Khi vẽ bản đồ không gian (E5), các chuyến thuộc ID 264/265 sẽ không có tọa độ hình học (polygon), do đó sẽ được hiển thị trên bảng số liệu phụ trợ (Side table / Tooltip KPI), không cố gắng tự tạo tọa độ giả.
