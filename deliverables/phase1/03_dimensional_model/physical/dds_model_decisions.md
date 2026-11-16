# Nhật ký quyết định mô hình DDS và các điểm còn mở

**Mục đích:** ghi lại các quyết định khi chuyển lược đồ sao logic chung sang đặc tả DDS vật lý, đồng thời lưu các câu hỏi nghiệp vụ cần chủ sở hữu phù hợp xem xét. Không chỉnh sửa tài liệu nguồn của thành viên khác.

## 1. Quyết định vật lý của Trực

| ID | Quyết định | Lý do / hệ quả |
|---|---|---|
| **PD-01** | Dùng các kiểu SQL tương đối độc lập với hệ quản trị (`BIGINT`, `INT`, `SMALLINT`, `DECIMAL`, `DATE`, `TIMESTAMP(6) WITHOUT TIME ZONE`, `VARCHAR`, `BOOLEAN`), chưa chọn hệ quản trị cơ sở dữ liệu cụ thể. | Đầu vào Phase 1 chưa chỉ định hệ quản trị. Khi triển khai có thể ánh xạ `BOOLEAN` và cú pháp timestamp theo hệ thống thực tế. |
| **PD-02** | Giữ `SourceFileMonth` và thêm `SourceRowNumber` vào Fact. | Cặp này chỉ ra vị trí dòng trong đúng bộ tệp nguồn đã chọn và giúp giữ cả các dòng trùng hoàn toàn. Mã SHA-256 tiếp tục nằm trong danh sách tệp nguồn, không lặp lại trên từng dòng Fact. Đây là lựa chọn vật lý của Trực cho OD-13. |
| **PD-03** | Dùng PascalCase cho tên vật lý, nhất quán với mô hình logic của Lộc. | Tên cột nguồn được ánh xạ trong từ điển. Ví dụ `total_amount` thành `TotalAmount`. Đây là lựa chọn đặt tên của Trực cho OD-14. |
| **PD-04** | Dùng `TripRecordKey BIGINT` làm khóa thay thế cho Fact; dùng khóa thay thế số nguyên riêng cho taxi zone/vendor/rate/payment; giữ khóa thông minh đã thống nhất cho ngày, giờ và nhóm khách. | Fact có 77,9 triệu dòng. Mã nguồn vẫn là khóa nghiệp vụ, tách biệt với khóa thay thế của các chiều. |
| **PD-05** | Dùng `DECIMAL(18,4)` cho USD và `DECIMAL(12,2)` cho dặm; cho phép số âm và giữ NULL của nguồn. | Tránh sai số số thực nhị phân, vẫn chứa giá trị dặm lớn nhất quan sát được và giữ thêm độ chính xác cho chuyển đổi nguồn. Quy tắc chuyển đổi khi nạp thuộc Phase 2. |
| **PD-06** | Giữ toàn bộ 77.966.324 bản ghi nguồn; tạo `IsInStudyPeriod` theo ngày đón; không xóa dòng âm, dòng trùng hoặc ngoại lai. | Cho phép đối soát với nguồn và hỗ trợ nhiều cách định nghĩa số chuyến/doanh thu. Báo cáo trong phạm vi nghiên cứu mặc định lọc cờ TRUE. |
| **PD-07** | Chỉ ghi `ExtraResidualAmount` như chỉ số đo dẫn xuất đang đề xuất, kèm công thức và giới hạn trong đặc tả vật lý. | Đây là phần dư để đối soát, không phải khoản phí do TLC định nghĩa. Chỉ dùng nếu Phúc duyệt OD-02; vẫn giữ `ExtraAmount` riêng và tránh cộng trùng với các khoản phụ phí thành phần. |
| **PD-08** | Không đưa thuộc tính ngày lễ vào `DimDate` cơ sở; lưu dữ liệu hình học bên ngoài và liên kết bằng `LocationID`/`HasGeometry`. | Lịch ngày lễ và các vùng hình học không phải trường gốc trong dữ liệu cuốc xe. Giữ ID 264/265 nhưng không tự tạo hình học. |

## 2. Câu hỏi mô hình đã xử lý

| ID | Trạng thái / cách thể hiện trong DDS | Bằng chứng và hệ quả còn lại |
|---|---|---|
| **OD-05 – RatecodeID 99** | **Đã xử lý ở DDS:** giữ mã 99 thành thành viên khóa nghiệp vụ riêng; -1 chỉ dành cho thiếu/không hợp lệ. | Có 347.274 dòng quan sát mang mã 99, khác với NULL. Không gộp mã 99 vào nhóm Không xác định. |
| **OD-06 – Nhãn zone 264/265 và nhóm không xác định** | **Đã xử lý ở DDS:** sao chép nhãn bảng tra cứu nguyên văn; ID 264 = `Unknown`/`N/A`, ID 265 = `N/A`/`Outside of NYC`; `TaxiZoneKey=-1` có nhãn thiếu mã riêng. Cả hai ID hợp lệ đều có `HasGeometry=FALSE`. | Tệp CSV có 265 ID nhưng shapefile chỉ có 263 polygon. Không tạo hình học giả. Bản nháp Dimension cũ có chỗ ghi khác bảng tra cứu cho ID 264; đặc tả vật lý theo đúng CSV. |
| **OD-10 – Pickup ngoài năm nghiên cứu** | **Trực đã chốt cho mô hình:** giữ 623 dòng pickup ngoài 2022–2023 và đánh dấu `IsInStudyPeriod=FALSE`. | Bảo toàn số dòng nguồn. Phân tích trong kỳ lọc cờ; đây là lựa chọn mô hình, không phải hướng dẫn nạp dữ liệu. |
| **OD-11 – NULL của phụ phí ùn tắc/sân bay** | **Đã chốt cách lưu:** giữ NULL và diễn giải là “nguồn không ghi nhận giá trị”; không đổi thành 0 và không kết luận chắc chắn là không áp dụng. | NULL đồng thời xuất hiện trong nhóm thiếu siêu dữ liệu. Cách diễn giải thận trọng này giữ nguyên trạng thái nguồn. Chỉ công thức phần dư tùy chọn mới dùng `COALESCE(...,0)`. |
| **OD-12 – Nhóm thiếu thông tin** | **Đã xử lý ở DDS:** giữ mã thanh toán 0 riêng; NULL của biểu giá/số khách vào thành viên thiếu riêng; khi phân tích phải hiển thị các nhóm này, không âm thầm lọc bỏ. | 2.677.659 dòng (3,43%) cùng thiếu passenger/rate và có payment code 0. Không suy đoán mô tả chính thức của code 0. |
| **OD-13 – SourceRowNumber** | **Trực đã chốt:** thêm `SourceRowNumber BIGINT`; đề xuất ràng buộc duy nhất `(SourceFileMonth, SourceRowNumber)` trên bộ tệp đã chọn và không bị thay đổi. | Giữ định danh dòng nguồn trong DDS; mã SHA-256 trong danh sách tệp chứng minh các tệp có còn nguyên vẹn hay không. |
| **OD-14 – Quy ước tên chỉ số đo** | **Trực đã chốt:** dùng PascalCase cho tên vật lý. | Ví dụ `total_amount` thành `TotalAmount`; các tên nguồn được ánh xạ trong từ điển. |

## 3. Điểm còn mở cần chủ sở hữu metric/nguồn quyết định

| ID | Câu hỏi còn mở | Cách mô hình hỗ trợ / cách hiểu tạm thời | Chủ sở hữu |
|---|---|---|---|
| **OD-01** | Định nghĩa nghiệp vụ của số chuyến (Trip Count): đếm mọi bản ghi nguồn, đếm bản ghi có TotalAmount không âm, hay loại cả hai dòng trong cặp đảo giao dịch ứng viên. | Lưu `TripRecordCount=1` và `IsNegativeTotalAmount`; hỗ trợ hai cách đầu. Cách đếm ròng cần thêm phân loại theo cặp, hiện chưa có trong mô hình logic. Các câu hỏi phụ thuộc số chuyến và doanh thu/chuyến bị ảnh hưởng. | Phúc |
| **OD-02** | Có dùng phân rã doanh thu đầy đủ khi `total_amount` khác tổng các cấu phần hay không. | `TotalAmount` vẫn là chỉ số đo duy nhất cho Tổng doanh thu. `ExtraResidualAmount` là tùy chọn, phải gọi là “phần dư phụ phí khác”, không phải phí TLC. Có 26,0% dòng `payment_type <> 0` lệch vượt dung sai, chủ yếu ở VendorID 1. | Phúc |
| **OD-03** | Mô tả/nhóm chính thức của `payment_type=0`. | Giữ `PaymentTypeID=0` thành viên riêng, nhãn trung tính “Mã 0 – chưa có trong từ điển 2022–2023”. Không gộp vào -1. | Dũng |
| **OD-04** | Tên chính thức của VendorID 5/6 và cách ghi thống nhất cho VendorID 2. | Giữ mã 5 và 6 riêng, tạm hiển thị “Mã 5”/“Mã 6” cho tới khi xác minh. VendorID 2 dùng tên TLC “VeriFone Inc.”; cần thống nhất tên ngắn là VTS hay VTS/Curb. | Dũng, Phúc |
| **OD-07** | Quy tắc duy nhất được duyệt để xác định tốc độ hợp lệ. | Đặc tả vật lý đang ghi quy tắc tạm trong bảng thuật ngữ chỉ số: thời lượng ≥60 giây, quãng đường >0,1 dặm, tốc độ 1–80 dặm/giờ. Một phần yêu cầu khác ghi ngưỡng 100 dặm/giờ; báo cáo cần nêu rõ lựa chọn này. | Phúc (Dũng đối chiếu ghi chú nguồn) |
| **OD-08** | Ranh giới khung giờ trong ngày được duyệt. | Bảng chiều giờ có thuộc tính mã/tên/thứ tự cho phép NULL; ranh giới đề xuất: NIGHT (đêm) 00–05, MORN (sáng) 06–10, MID (trưa) 11–13, AFT (chiều) 14–17, EVE (tối) 18–23. Ghi là đề xuất đến khi được duyệt. | Phúc |
| **OD-09** | Có tách riêng dải khoảng cách bất thường trên 100 dặm hay không. | Giữ dải hiện tại “Rất dài (>10 dặm)”, đồng thời giữ dặm gốc. Có 2.833 dòng trên 100 dặm, cao nhất 389.678,46; khi báo cáo trung bình cần nêu rõ quy tắc xử lý ngoại lai. | Phúc |
| **C7-TIE** | Công thức đếm và cách xử lý hòa điểm khi xếp hạng tuyến Top N. | M11 dùng `COUNT(TripID)`, nhưng mô hình không có cột `TripID`; cần dùng định nghĩa số chuyến được chốt theo OD-01. M11 nêu `DENSE_RANK()` hoặc xếp phụ theo `total_amount`, nhưng chưa chọn một quy tắc duy nhất. Cần quyết định có nhận thêm tuyến đồng hạng ở ngưỡng N hay dùng doanh thu để phá hòa. | Phúc |
| **OD-15** | Duyệt sơ đồ khái niệm. | Bản nháp sơ đồ khái niệm của Dũng/Lộc tồn tại riêng; đây không phải điều kiện để dùng từ điển vật lý và sơ đồ logic chung trong gói này. | Dũng |

## 4. Giới hạn nguồn và phân tích

- Hồ sơ đã chọn gồm 24 tệp Parquet Yellow Taxi từ 01/2022 đến 12/2023, tổng cộng 77.966.324 dòng. Không suy rộng kết quả sang dữ liệu TLC 2009–2026.
- Lược đồ nguồn thay đổi theo năm: `airport_fee` đổi tên thành `Airport_fee` từ 02/2023; kiểu dữ liệu số năm 2022 và 2023 cũng khác nhau. Hai tên trường ánh xạ về cùng một thuộc tính logic.
- `passenger_count` do tài xế tự báo cáo, không phải số hành khách duy nhất đã xác minh. NULL khác 0.
- Nguồn không ghi nhận đầy đủ tiền boa tiền mặt. `total_amount` không bao gồm tiền boa tiền mặt; đây là giới hạn của phân tích doanh thu và tip.
- Timestamp pickup/drop-off không có thông tin múi giờ. Thời lượng quanh thời điểm đổi giờ mùa hè có thể bị ảnh hưởng.
- ID trong bảng tra cứu 264/265 là thành viên hợp lệ, không có dữ liệu hình học; không phải mã thiếu/không hợp lệ.
- `TotalAmount < 0` chỉ cho biết số tiền âm. Hồ sơ có các dòng âm không có dòng dương ứng viên tương ứng, nên không thể kết luận mọi dòng âm đều là bút toán đảo.

## 5. Bàn giao rà soát

Gói đặc tả vật lý đã sẵn sàng để chủ sở hữu xem các điểm OD-01–04, OD-07–09 và C7-TIE. Cho đến khi được duyệt, dùng các lựa chọn tạm thời đã ghi và chú thích các phép tính phụ thuộc. Ma trận đối chiếu lược đồ theo từng yêu cầu nằm trong [physical_model_coverage.md](physical_model_coverage.md).
