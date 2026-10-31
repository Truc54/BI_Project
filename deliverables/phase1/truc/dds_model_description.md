# Mô tả mô hình DDS Yellow Taxi (Phase 1)

**Phạm vi dữ liệu:** 24 tệp TLC Yellow Taxi theo tháng, 01/2022–12/2023.  
**Mô hình:** một bảng Fact chuyến đi và tám bảng chiều.  
**Đầu vào:** lược đồ logic của Lộc và Dũng, các chỉ số đo/yêu cầu của Phúc, cùng hồ sơ quan sát trên các tệp đã chọn.

## 1. Quy trình và mức hạt

Mô hình ghi nhận quy trình vận chuyển hành khách Yellow Taxi ở mức bản ghi do hệ thống TPEP công bố. Một dòng trong `FactYellowTaxiTrip` tương ứng với **một dòng trong một tệp nguồn**, không khẳng định đó là một chuyến đi duy nhất. Nguồn không có `trip_id`; hồ sơ còn phát hiện 3 dòng trùng hoàn toàn và nhiều cặp dòng âm/dương có khả năng là đảo giao dịch. Vì vậy bảng Fact giữ nguyên mọi dòng, kể cả dòng âm và dòng trùng.

Bảng Fact chứa toàn bộ **77.966.324** dòng của 24 tệp. `IsInStudyPeriod` đánh dấu ngày đón trong khoảng `[2022-01-01, 2024-01-01)`; 77.965.701 dòng thuộc kỳ, 623 dòng có ngày đón ngoài kỳ vẫn được giữ để đối soát nguồn. Báo cáo Phase 1 mặc định lọc cờ này. Các con số và kết luận trong bộ tài liệu chỉ mô tả 2022–2023, không đại diện cho toàn giai đoạn 2009–2026 trong đề bài.

`TripRecordKey` là khóa thay thế của DDS, không phải mã chuyến nguồn. `SourceFileMonth` cùng `SourceRowNumber` ghi lại vị trí dòng trong tệp tháng và tạo định danh có điều kiện trên đúng bộ tệp nguồn. Không khử trùng lặp.

## 2. Bảng Fact và các chỉ số đo

`FactYellowTaxiTrip` là bảng Fact giao dịch duy nhất cho C1–C8 và E1–E5. Bảng giữ các khóa theo vai trò, dấu thời gian gốc, mã/cờ nguồn, số khách tài xế báo cáo, dặm đồng hồ tính cước và các khoản tiền. `TripRecordCount = 1` là chỉ số đo đếm dòng nguồn. Do Phúc chưa chốt định nghĩa nghiệp vụ của số chuyến, mô hình hỗ trợ đếm mọi bản ghi hoặc chỉ đếm bản ghi có `TotalAmount` không âm; không tự kết luận rằng một dòng âm là bút toán đảo hay loại các cặp ứng viên.

Các chỉ số có thể cộng dồn gồm `PassengerCount`, `TripDistanceMiles`, `FareAmount`, `ExtraAmount`, `MtaTaxAmount`, `TipAmount`, `TollsAmount`, `ImprovementSurchargeAmount`, `CongestionSurchargeAmount`, `AirportFeeAmount` và `TotalAmount`. NULL của số khách, phụ phí ùn tắc, phí sân bay và cờ lưu-chuyển-tiếp được giữ nguyên; NULL không bị đổi thành 0. Các chỉ số tiền tệ dùng USD. `TotalAmount` là trường chuẩn cho tổng doanh thu và không gồm tip tiền mặt. `ExtraAmount` được giữ để tra cứu nhưng không cộng cùng lúc với các khoản phí riêng vì dữ liệu có sai lệch/khả năng chồng lấp theo VendorID.

Thời lượng được tính từ hai timestamp gốc và giữ cả số âm. Các tỷ lệ và giá trị trung bình phải tính lại từ tử số/mẫu số trong cùng phạm vi; không cộng tỷ lệ hoặc lấy trung bình của các giá trị trung bình. `ExtraResidualAmount` là chỉ số đo dẫn xuất đang chờ Phúc duyệt: phần còn lại được tính để phân rã `TotalAmount`, không phải khoản phí TLC. Công thức và điều kiện lọc chi tiết nằm trong [từ điển vật lý](dds_physical_spec.md).

## 3. Các bảng chiều và quan hệ

Mỗi dòng Fact tham chiếu đúng một thành viên trong mỗi bảng chiều. Các khóa ngoại được lưu `NOT NULL`; khóa thiếu hoặc ngoài danh mục dùng thành viên đặc biệt tương ứng. Khóa thay thế của bảng chiều không mang ý nghĩa nghiệp vụ, trừ các khóa thông minh đã được Lộc xác định cho ngày, giờ và nhóm khách.

| Bảng chiều | Mức hạt và mục đích | Phân cấp/thuộc tính phân tích |
|---|---|---|
| `DimDate` | Một dòng mỗi ngày lịch, 2021-01-01 đến 2024-12-31, cộng thành viên `-1` cho ngày không hợp lệ/ngoài phạm vi. Được dùng hai lần trong Fact. | Năm → quý → tháng → ngày; thêm thứ trong tuần, cuối tuần, số ngày trong tháng và cờ kỳ nghiên cứu. |
| `DimTime` | Một dòng mỗi phút trong ngày (1.440 thành viên); Fact giữ timestamp gốc đến độ chính xác nguồn để tính thời lượng. | Khung giờ trong ngày → giờ → phút. Ranh giới khung giờ là đề xuất đang chờ duyệt; chưa xem phụ phí theo giờ là định nghĩa nghiệp vụ đã xác nhận. |
| `DimTaxiZone` | Một dòng mỗi `LocationID` trong bảng tra cứu (1–265), cộng `-1` cho mã thiếu/không hợp lệ. | Quận → Zone → LocationID; `ServiceZone` là thuộc tính bổ sung. `HasGeometry` cho biết zone có polygon hay không. |
| `DimVendor` | Một dòng mỗi mã VendorID được giữ, gồm các mã quan sát được 1, 2, 5, 6 và thành viên `-1`. | Tên đầy đủ/tên ngắn của vendor. Giữ riêng mã nguồn; nhãn 5/6 chưa được TLC xác nhận. |
| `DimRateCode` | Một dòng mỗi mã biểu giá, gồm 1–6, 99 và thành viên `-1`. | Nhóm biểu giá → mô tả → mã. Mã 99 có thành viên riêng, khác NULL. |
| `DimPaymentType` | Một dòng mỗi mã thanh toán 0–6 và thành viên `-1`. Giữ mã 6 dù không quan sát trong mẫu. | Nhóm thanh toán → mô tả → mã; cờ cho biết có thể dùng để tính tip điện tử. Mã 0 được giữ riêng nhưng chưa có mô tả trong từ điển 2022–2023. |
| `DimPassengerGroup` | Một dòng cho từng giá trị số khách báo cáo, khóa thông minh bằng giá trị; `-1` cho NULL và `99` làm nhóm dự phòng từ 10 trở lên. | Một khách (1), nhóm nhỏ (2–4), nhóm lớn (5+), không xác định (0 hoặc NULL). 0 và NULL vẫn là hai thành viên riêng nhưng cùng nhóm Không xác định. |
| `DimDistanceBand` | Một dòng mỗi dải cự ly dẫn xuất, khóa 1–5 và `-1` cho NULL/âm. | 0–1, >1–3, >3–5, >5–10, >10 dặm. Giữ dặm gốc trong Fact. |

Các chiều ngày, giờ và taxi zone được dùng lại theo nhiều **vai trò**. Fact có sáu khóa riêng:

| Vai trò | Khóa trong Fact | Bảng chiều dùng chung |
|---|---|---|
| Ngày đón / ngày trả | `PickupDateKey` / `DropoffDateKey` | `DimDate` |
| Giờ đón / giờ trả | `PickupTimeKey` / `DropoffTimeKey` | `DimTime` |
| Vùng đón / vùng trả | `PickupTaxiZoneKey` / `DropoffTaxiZoneKey` | `DimTaxiZone` |

Các khóa còn lại là `VendorKey`, `RateCodeKey`, `PaymentTypeKey`, `PassengerGroupKey` và `DistanceBandKey`. Mặc định gán doanh thu và nhu cầu theo vùng đón; vẫn phân tích riêng vùng trả qua vai trò Drop-off.

## 4. Tuyến, địa lý và các phân cấp

Không tạo bảng chiều tuyến riêng. Tuyến là cặp có thứ tự `(PickupTaxiZoneKey, DropoffTaxiZoneKey)`; A→B khác B→A. Có thể nhóm tiếp theo cặp quận ở hai đầu. Cách này giữ hướng tuyến và dùng lại đầy đủ thuộc tính của `DimTaxiZone`.

Bảng tra cứu có 265 ID nhưng tệp vùng hình học chỉ có polygon cho ID 1–263. `LocationID` 264 (bảng tra cứu ghi Borough `Unknown`, Zone `N/A`) và 265 (Borough `N/A`, Zone `Outside of NYC`) là thành viên hợp lệ của `DimTaxiZone`, với `HasGeometry = FALSE`; không tạo hình học giả. Thành viên `TaxiZoneKey = -1` dùng nhãn riêng “Thiếu mã vùng”, không nhập chung với ID 264.

## 5. Hỗ trợ yêu cầu phân tích

- Thời gian: ngày → tháng → quý/năm; thứ và cuối tuần; khung giờ trong ngày → giờ → phút; ngày đón/trả độc lập.
- Địa lý: Quận → Zone → LocationID, độc lập theo điểm đón/trả; bản đồ chỉ dùng thành viên có dữ liệu hình học.
- Nhà cung cấp, biểu giá và thanh toán: giữ mã TLC gốc và mô tả; có thể phân tích cơ cấu theo mã mà không làm mất mã lạ hoặc chưa có mô tả.
- Nhóm khách và cự ly: nhóm được mà vẫn giữ giá trị số khách/dặm ban đầu để tính tổng/trung bình.
- Doanh thu, tỷ lệ tip, tốc độ, thời lượng và doanh thu/chuyến: giữ đầu vào gốc, vai trò thời gian/không gian và điều kiện lọc để tính khi truy vấn.
- So sánh tháng 5–6 và MoM/YoY: dùng `YearMonth`, số ngày trong tháng và các chỉ số đo cộng dồn. Không suy nguyên nhân từ dữ liệu thời tiết/sự kiện ngoài nguồn; so riêng tháng 5 và tháng 6 của từng năm.

Đường truy vấn cụ thể cho từng yêu cầu nằm trong [physical_model_coverage.md](physical_model_coverage.md). Các cách tính phụ thuộc quyết định nghiệp vụ còn mở được liệt kê trong [dds_model_decisions.md](dds_model_decisions.md).

## 6. Giới hạn dữ liệu nguồn cần nêu khi diễn giải

1. Parquet 2022 lưu một số mã nguyên dưới kiểu DOUBLE; lược đồ đổi kiểu ở 2023 và `airport_fee` đổi cách viết thành `Airport_fee` từ 2023-02. Đây là cùng một trường logic, không phải hai chỉ số đo.
2. `passenger_count` do tài xế nhập, không phải số hành khách duy nhất đã xác minh. NULL khác 0.
3. Tip ghi nhận trong `tip_amount` chủ yếu là tip điện tử; tip tiền mặt không được đo đầy đủ. `total_amount` không bao gồm tip tiền mặt.
4. Timestamp là giờ địa phương New York không kèm múi giờ. Thời lượng quanh thời điểm đổi giờ mùa hè có thể lệch một giờ.
5. Các dòng âm, thời lượng âm/0/quá lớn, khoảng cách 0 hoặc cực lớn được giữ ở mức hạt nguồn; cờ lọc chỉ dành cho chỉ số liên quan.
6. NULL ở `congestion_surcharge` và `airport_fee` nghĩa là nguồn không ghi nhận giá trị, không chứng minh khoản phí bằng 0 hoặc không áp dụng.
7. Một phần giá trị `total_amount` không khớp tổng các cột thành phần, đặc biệt với VendorID 1. Tổng doanh thu vì vậy luôn dùng `TotalAmount`; nếu phân rã bằng giá trị phần dư thì phải ghi rõ tính chất của nó.

## 7. Tài liệu mô hình

- [Lược đồ sao logic chung của Lộc/Dũng](../loc/dds_logical_model.drawio)
- [Từ điển dữ liệu vật lý](dds_physical_spec.md)
- [Ma trận đối chiếu yêu cầu](physical_model_coverage.md)
- [Nhật ký quyết định mô hình](dds_model_decisions.md)
