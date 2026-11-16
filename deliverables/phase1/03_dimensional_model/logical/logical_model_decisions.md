# Logical Model Decisions: Grain, Roles, Members, Derivations (Phase 1)

**Tác giả:** Lộc
**Mục đích:**
- Ghi lại các quyết định về grain, vai trò, hướng tuyến, thành viên đặc biệt và nhóm dẫn xuất (Gói E).
- Ghi các điểm còn mở cần chủ sở hữu khác chốt.
- Ghi các lỗi phát hiện trong tài liệu của thành viên khác. Lộc **không** tự sửa file của Phúc, Dũng hay Trực.

Trực dùng tài liệu này làm đầu vào cho `dds_model_decisions.md`.
**Căn cứ số liệu:** [selected_data_profile_observed.md](selected_data_profile_observed.md), [profile_results.json](profile_results.json)

---

## 1. Quyết định đã chốt (trong phạm vi Lộc dẫn dắt)

| ID | Quyết định | Lý do / bằng chứng |
|:---|:---|:---|
| D-01 | Grain của Fact = **một bản ghi chuyến đi trong 24 tệp nguồn**, không phải chuyến duy nhất | Không có `trip_id`; 558.184 ứng viên cặp đảo bút toán; 3 dòng trùng hoàn toàn |
| D-02 | Một Fact duy nhất `FactYellowTaxiTrip` cho C1–C8 và E1–E5 | Mọi câu hỏi là tổng hợp trên bản ghi cuốc xe; ở mức logic không cần snapshot hay aggregate |
| D-03 | Sáu khóa role-playing: Pickup/Drop-off × Date, Time, TaxiZone | C4, C6, E5 cần đếm theo từng vai trò; pickup và drop-off lệch nhau rõ ở Queens/Brooklyn |
| D-04 | Tuyến = cặp **có thứ tự** `(PickupTaxiZoneKey, DropoffTaxiZoneKey)`; A→B ≠ B→A; không tạo `DimRoute` | Thực hiện QĐ6 của Phúc; mọi thuộc tính tuyến đã có qua hai vai trò của zone |
| D-05 | Gán borough mặc định theo **pickup**; drop-off luôn chọn được trên cùng dòng Fact | Thực hiện QĐ5 của Phúc |
| D-06 | ID 264/265 là **thành viên hợp lệ** của `DimTaxiZone` (`HasGeometry = FALSE`), không tạo polygon. `-1` chỉ dành cho NULL hoặc ID ngoài 1–265 | Overview, Dũng, QĐ10 của Phúc; 1,22% pickup thuộc 264/265; 0 ID không hợp lệ |
| D-07 | Fact giữ **giá trị gốc**: `PassengerCount` NULL giữ NULL; `TripDistanceMiles`, timestamp và các khoản tiền giữ nguyên, kể cả âm | Phân biệt "không ghi nhận" với "bằng 0"; tính lại được mọi chỉ số |
| D-08 | `DimPassengerGroup` lưu theo giá trị (`-1`/NULL và `0` cùng roll-up vào UNKNOWN); `DimDistanceBand` 5 dải; giá trị gốc ở Fact | C5; thực hiện QĐ3–QĐ4 của Phúc, không thay đổi thang |
| D-09 | Total Revenue = `SUM(TotalAmount)`; không cộng các cột thành phần | QĐ1 của Phúc; ở VendorID 1, 94,6% dòng có `total_amount` ≠ tổng cấu phần |
| D-10 | Thuộc tính dẫn xuất tất định trên cùng dòng: `TripDurationSeconds`, `IsValidDuration` (M7), `IsValidForTipRatio` (QĐ2), `IsNegativeTotalAmount`, `IsInStudyPeriod` | Input của M6, M7, M10; không làm mất dữ liệu gốc. Các thuộc tính phụ thuộc điểm mở xem OD-02, OD-07 |
| D-11 | `DimDate` trải 2021-01-01 … 2024-12-31; ngày ngoài phạm vi trỏ `-1`; timestamp gốc giữ trong Fact | Chứa được cuốc vắt qua năm; 593 dòng (pickup) và 455 dòng (drop-off) ngoài phạm vi vẫn còn trong Fact |
| D-12 | `DimTime` ở mức phút (1.440 dòng); thời lượng tính từ timestamp gốc mức giây | Phân cấp `Daypart → Hour → Minute` của Phúc |
| D-13 | Fact chứa **toàn bộ** 77.966.324 bản ghi; lọc kỳ nghiên cứu bằng `IsInStudyPeriod` | Đối soát được với tệp. Cách xử lý dòng ngoài kỳ vẫn mở với Dũng ở OD-10 |
| D-14 | Chiến lược khóa: smart key cho `DimDate` (`YYYYMMDD`), `DimTime` (`HHMM`), `DimPassengerGroup` (= giá trị); surrogate key cho các chiều còn lại; `-1` luôn là "không có giá trị hợp lệ" | [supporting_dimensions_logical.md §0](supporting_dimensions_logical.md#0-chiến-lược-khóa-của-toàn-mô-hình) |
| D-15 | `IsNegativeTotalAmount` chỉ là quy tắc **theo dấu** (`TotalAmount < 0`); không gán nghĩa "bút toán đảo" cho mọi dòng âm | 74.390 dòng âm không có dòng dương tương ứng |

## 2. Điểm mở cần chủ sở hữu khác chốt

| ID | Vấn đề | Phát hiện | Đề xuất của Lộc (chưa áp dụng như quyết định) | Chủ sở hữu |
|:---|:---|:---|:---|:---|
| **OD-01** | Định nghĩa Trip Count | M1 hiện là `COUNT(FactTripKey)`. 558.184 ứng viên cặp đảo; 632.589 dòng âm | Ba phương án tại [grain §4.1](fact_grain_and_process.md#41-trip-count-chưa-chốt-od-01): Trip Record Count (= M1 hiện hành), Operational Trip Count (loại dòng âm, cuốc bị hủy vẫn đếm 1 lần), Net Trip Count (loại cả cặp, cần thêm cờ cấp cặp). Tác động: M1, M2 trung bình, M8 trung bình, M10, C1–C7, E2–E4. Doanh thu không bị ảnh hưởng | **Phúc** |
| **OD-02** | Phân rã cấu phần doanh thu (M3 dòng 46, QĐ8) | `total_amount ≠` tổng cấu phần ở 26,0% dòng `PAYMENT_NZ`, chủ yếu VendorID 1 | Dùng `ExtraResidualAmount`, một **phần dư** định nghĩa sao cho tổng cấu phần = `TotalAmount`. Báo cáo phải gọi đây là "phần dư phụ phí khác", không phải khoản phí TLC. Phương án khác: chỉ phân rã Fare/Tip/Tolls, gộp phần còn lại thành `TotalAmount − Fare − Tip − Tolls` | **Phúc** |
| **OD-03** | `payment_type = 0` không có trong `DimPaymentType` | 2.677.659 dòng (3,43%) trùng đúng khối thiếu metadata; mã 6 (Voided) không xuất hiện | Thêm thành viên `PaymentTypeID = 0`, **không** gộp vào `-1`. Lộc **không đặt tên chính thức**: Dũng tra phiên bản từ điển TLC hiện hành; nếu không có thì ghi "Mã 0 – chưa có trong từ điển 2022–2023". Giữ thành viên 6 dù không quan sát được | **Dũng** |
| **OD-04** | VendorID 5 và 6 | 6: 68.269 dòng (01/2022–12/2023); 5: 143 dòng (01–09/2022); tất cả thuộc khối `payment_type = 0` | Thêm hai thành viên riêng giữ mã gốc, **không** gộp `-1` như [metric_decisions.md](../phuc/metric_decisions.md) dòng 109 đề xuất. Lộc **không đặt tên**: Dũng tra từ điển TLC; nếu không có thì ghi "Chưa có trong từ điển 2022–2023". Đồng thời thống nhất tên VendorID 2 giữa Phúc (QĐ9: "VeriFone Inc. (VTS)") và Dũng ("VeriFone / Curb") | **Dũng**, Phúc |
| **OD-05** | `RatecodeID = 99` | 347.274 dòng; tách biệt với NULL (2.677.659). [source_field_dictionary.md](../dung/source_field_dictionary.md) dòng 70 gộp 99 vào `-1`; [reference_dimensions_logical.md](../dung/reference_dimensions_logical.md) dòng 107 giữ 99 là thành viên riêng | Giữ 99 là **thành viên riêng** (khớp dòng 107); `-1` chỉ dành cho NULL | **Dũng** |
| **OD-06** | Nhãn của 264/265 và của `-1` trong `DimTaxiZone` | Lookup gốc: 264 = (`Unknown`, `N/A`), 265 = (`N/A`, `Outside of NYC`). Dũng đổi nhãn (dòng 45–46). Thành viên `-1` cũng ghi Borough `Unknown` (dòng 35, 49), trùng nhãn với ID 264 khi roll-up | Giữ `Borough`/`Zone` đúng giá trị lookup; thêm thuộc tính hiển thị nếu cần. Thành viên `-1` dùng nhãn khác hẳn, ví dụ "Thiếu mã vùng" | **Dũng** |
| **OD-07** | Ngưỡng lọc thời lượng/tốc độ không thống nhất | [metric_glossary.md](../phuc/metric_glossary.md) dòng 138–140 (M9): ≥ 60 s, > 0,1 dặm, 1–80 mph. [requirements_traceability.md](../phuc/requirements_traceability.md) dòng 29 (E1): loại > 100 mph. [selected_data_profile.md của Dũng](../dung/selected_data_profile.md) dòng 81: "≤ 180 phút theo Phúc", nhưng Phúc không có quy tắc này. Ảnh hưởng: 6.793 dòng > 80 mph, 5.736 dòng > 100 mph, 84.794 dòng > 180 phút | `IsValidForSpeed` **tạm** cài theo M9 vì đây là định nghĩa trong glossary của chủ sở hữu metric. Phúc chốt một quy tắc duy nhất; Lộc sẽ sửa cờ nếu Phúc chọn khác | **Phúc**, Dũng |
| **OD-08** | Ranh giới giờ của Daypart | Phúc nêu tên 5 khung nhưng chưa có mốc giờ ([analysis_grain_matrix.md](../phuc/analysis_grain_matrix.md) dòng 38) | Đêm 00–05, Sáng 06–10, Trưa 11–13, Chiều 14–17, Tối 18–23 ([DimTime](supporting_dimensions_logical.md#2-dimtime-role-playing-pickup-time-drop-off-time)); chỉ là đề xuất | **Phúc** |
| **OD-09** | Cự ly bất thường | 2.833 dòng > 100 dặm (max 389.678,46) rơi vào dải "Rất dài" | Thêm dải "Bất thường (> 100 dặm)", hoặc giữ nguyên và ghi chú. Cự ly trung bình bị ảnh hưởng, nên cần lọc | **Phúc** |
| **OD-10** | Dòng có ngày pickup ngoài 2022–2023 | 623 dòng | Giữ trong DDS kèm `IsInStudyPeriod`, thay vì lọc bỏ ở ETL như [profile của Dũng](../dung/selected_data_profile.md) dòng 28. Hai cách cho cùng kết quả báo cáo | **Dũng**, Trực |
| **OD-11** | Ngữ nghĩa NULL của `congestion_surcharge` / `airport_fee` | NULL trùng khối thiếu metadata, không phải "ngoài vùng áp dụng" | NULL = **không ghi nhận**; Fact giữ NULL. Cần sửa diễn giải ở profile của Dũng, dòng 55–56 | **Dũng** |
| **OD-12** | Khối thiếu metadata (3,43%) trong phân tích theo biểu giá và thanh toán | Không có RateCode, PaymentType, số khách | Các dòng này nằm ở thành viên Unknown hoặc mã 0. Báo cáo C3, C5, E1 phải hiển thị nhóm này thay vì âm thầm loại | Phúc, Trực |
| **OD-13** | Lưu `SourceRowNumber` ở mức vật lý | Cần cho tuyên bố định danh `(SourceFileMonth, SourceRowNumber)` | Lưu dạng số nguyên. Nếu không lưu, phải bỏ tuyên bố định danh khỏi grain | **Trực** |
| **OD-14** | Quy ước đặt tên measure | Phúc dùng `snake_case` (`trip_record_count`, `FactTripKey` trong M1); Lộc dùng `PascalCase` (`TripRecordCount`, `TripRecordKey`) | Thống nhất một quy ước ở physical spec, kèm bảng ánh xạ tên | **Trực**, Phúc |
| **OD-15** | Sơ đồ mức khái niệm (conceptual) | Overview yêu cầu "conceptual and logical star-schema diagrams"; plan của Lộc chỉ nêu sơ đồ logic | Lộc đã bổ sung bản nháp [dds_conceptual_model.png](dds_conceptual_model.png); Dũng là đồng tác giả, cần duyệt | **Dũng** |

## 3. Lỗi phát hiện trong tài liệu của thành viên khác (Lộc không sửa)

| File : dòng | Vấn đề | Đề xuất |
|:---|:---|:---|
| [phuc/metric_glossary.md](../phuc/metric_glossary.md) : 14 | M1 = `COUNT(FactTripKey)`: tên khóa khác mô hình (`TripRecordKey`); chưa xử lý ứng viên cặp đảo | Chốt OD-01, OD-14 |
| [phuc/metric_glossary.md](../phuc/metric_glossary.md) : 46 | Công thức cấu phần `total_amount = fare + extra + …` sai với 94,6% dòng VendorID 1 | Ghi chú giới hạn; chốt OD-02 |
| [phuc/metric_glossary.md](../phuc/metric_glossary.md) : 138–140 so với [phuc/requirements_traceability.md](../phuc/requirements_traceability.md) : 29 | Ngưỡng tốc độ 1–80 mph và > 100 mph mâu thuẫn | Chốt OD-07 |
| [phuc/analysis_grain_matrix.md](../phuc/analysis_grain_matrix.md) : 38 | Daypart không có mốc giờ | Chốt OD-08 |
| [phuc/metric_decisions.md](../phuc/metric_decisions.md) : 109 | Gộp VendorID khác 1/2 vào `Unknown / Other`, mâu thuẫn với yêu cầu giữ mã gốc | Chốt OD-04 |
| [dung/source_field_dictionary.md](../dung/source_field_dictionary.md) : 31, 84 | `payment_type` chỉ liệt kê 1–6; mã 0 (3,43%) sẽ rơi vào `-1` | OD-03 |
| [dung/source_field_dictionary.md](../dung/source_field_dictionary.md) : 37, 40 và [dung/source_inventory.md](../dung/source_inventory.md) : 109, 112 | Chỉ nêu mức 0,30 và 1,25; dữ liệu có 1,00 (từ 12/2022) và 1,75 (từ 04/2023). Không nêu việc đổi tên `Airport_fee` từ 2023-02 | Bổ sung theo profile §1, §7 |
| [dung/source_field_dictionary.md](../dung/source_field_dictionary.md) : 70 so với [dung/reference_dimensions_logical.md](../dung/reference_dimensions_logical.md) : 107 | Xử lý `RatecodeID = 99` mâu thuẫn | OD-05 |
| [dung/reference_dimensions_logical.md](../dung/reference_dimensions_logical.md) : 35, 45–46, 49 | Đổi nhãn lookup của 264/265; nhãn `-1` trùng "Unknown" | OD-06 |
| [dung/reference_dimensions_logical.md](../dung/reference_dimensions_logical.md) : 78, 137 | VendorID và payment ngoài danh mục đều gộp `-1` | OD-03, OD-04 |
| [dung/selected_data_profile.md](../dung/selected_data_profile.md) : 19–102 | Nhiều số ước lượng khác số đo | Bảng đối chiếu tại [profile quan sát §9](selected_data_profile_observed.md#9-đối-chiếu-với-bản-profile-của-dũng-cần-hợp-nhất-lộc-không-sửa-file-của-dũng) |

## 4. Ghi chú nguồn (không cần quyết định, nhưng phải hiển thị trong báo cáo)

- Schema đổi từ 2023-02 (`Airport_fee`, kiểu dữ liệu); đây là cùng một trường logic.
- Timestamp là giờ địa phương không kèm múi giờ; ngày đổi giờ có thể làm lệch thời lượng ±1 giờ.
- `total_amount` không gồm tip tiền mặt (TLC). Trong dữ liệu, tip tiền mặt gần như luôn 0: chỉ 3.533 / 14.168.398 dòng tiền mặt có tip.
- Mức `improvement_surcharge` (0,30 → 1,00 từ 12/2022) và `airport_fee` (1,25 → 1,75 từ 04/2023) thay đổi trong kỳ; đây là input cho E3, E4.
- Mọi số liệu chỉ mô tả 24 tệp 2022–2023.
