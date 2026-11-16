# Fact Grain & Business Process (Phase 1)

**Tác giả:** Lộc (chủ trì grain & Fact, đồng chủ trì star schema cùng Dũng)
**Phạm vi dữ liệu:** 24 tệp Yellow Taxi Parquet 01/2022 – 12/2023, gồm 77.966.324 bản ghi, trong đó 77.965.701 bản ghi có pickup thuộc 2022–2023
**Tài liệu liên quan:** [Fact logic](fact_yellow_taxi_trip_logical.md), [Chiều hỗ trợ](supporting_dimensions_logical.md), [Profile quan sát](selected_data_profile_observed.md), [Quyết định mô hình](logical_model_decisions.md), [Reference dimensions (Dũng)](../dung/reference_dimensions_logical.md), [Requirements (Phúc)](../phuc/requirements_traceability.md)

> Mọi số liệu được đo trên 24 tệp đã chọn bằng [profile_selected_data.py](profile_selected_data.py), kết quả lưu tại [profile_results.json](profile_results.json) (tên khóa JSON ghi trong ngoặc vuông). Trừ khi ghi khác, tập tính là **toàn bộ 77.966.324 dòng** (`ALL_ROWS`). Kết quả chỉ đại diện cho 2022–2023, không suy rộng cho 2009–2026.

---

## 1. Quy trình nghiệp vụ (Business Process)

**Quy trình được mô hình hóa:** *ghi nhận một cuốc xe Yellow Taxi trên thiết bị tính cước TPEP*.

Mỗi lần tài xế bật đồng hồ (pickup) và tắt đồng hồ (drop-off), thiết bị của nhà cung cấp công nghệ (`VendorID`) tạo một bản ghi gồm:
- thời điểm đón/trả và vùng đón/trả;
- số khách do tài xế nhập;
- quãng đường;
- biểu giá và phương thức thanh toán;
- các khoản tiền.

TLC công bố các bản ghi này theo tệp tháng.

Một quy trình là đủ cho C1–C8 và E1–E5, vì mọi câu hỏi đều là tổng hợp trên tập bản ghi cuốc xe theo các góc nhìn thời gian, không gian, nhà cung cấp, biểu giá, thanh toán, nhóm khách và cự ly. Phase 1 không cần Fact thứ hai (snapshot hay aggregate), vì mọi chỉ số đều tính được từ Fact cấp bản ghi.

## 2. Tuyên bố Grain

> **Một dòng trong `FactYellowTaxiTrip` = một bản ghi chuyến đi (trip record) trong 24 tệp nguồn TLC Yellow Taxi đã chọn.**

Grain là **bản ghi nguồn**, **không phải** "một chuyến đi duy nhất được bảo đảm". Các bằng chứng quan sát được:

| Bằng chứng | Số liệu quan sát | Hệ quả cho grain |
|:---|:---|:---|
| Nguồn không có cột định danh chuyến đi (`trip_id`) | 19 cột, không cột nào là khóa (`_meta.files[].schema`) | Không chứng minh được mỗi dòng là một chuyến duy nhất |
| Dòng trùng hoàn toàn trên cả 19 cột | 3 nhóm, thừa 3 dòng [`exact_duplicates`] | Không phân biệt được trùng thật hay hai cuốc giống hệt; giữ nguyên |
| Nhóm dòng cùng VendorID, thời điểm đón/trả, PU và DO | 558.324 nhóm; trong đó 558.184 nhóm gồm đúng 1 dòng `total_amount < 0` và 1 dòng `> 0`, gọi là **ứng viên cặp đảo bút toán**; 549.801 cặp trong số đó có tổng tiền đối xứng chính xác (âm = −dương) [`candidate_duplicates`] | Một sự kiện nghiệp vụ (cuốc bị hủy/tranh chấp/hoàn tiền) **có thể** sinh 2 dòng. Dữ liệu không có cột đánh dấu bút toán đảo, nên đây là suy luận từ mẫu số liệu, không phải định danh chính thức |
| Dòng có `total_amount < 0` | 632.589; 558.199 dòng (88,2%) có ít nhất một dòng dương cùng khóa ứng viên [`negative_with_original`] | 74.390 dòng âm không có dòng dương tương ứng, nên không thể coi mọi dòng âm là bút toán đảo |
| Pickup ngoài tháng của tệp | 2.194 dòng (0,003%) [`monthly`] | Tháng của tệp không phải ranh giới chuẩn của thời gian chuyến |

### Định danh bản ghi (record identity)

Nguồn không có khóa nghiệp vụ, nên một bản ghi được nhận diện bằng **nguồn gốc** của nó:

> `(SourceFileMonth, SourceRowNumber)`: tháng của tệp nguồn và số thứ tự dòng trong tệp (bắt đầu từ 0).

- Cặp này duy nhất theo cấu tạo, miễn tệp nguồn không bị thay thế. Overview có ghi manifest chứa SHA-256 của từng tệp, dùng để kiểm chứng điều kiện này.
- Cả hai thuộc tính là **degenerate dimension** trong Fact. `SourceRowNumber` là đề xuất của Lộc; Trực quyết định ở mức vật lý có lưu hay không (xem [OD-13](logical_model_decisions.md)). Nếu không lưu, tuyên bố định danh ở trên không còn kiểm chứng được trong DDS.
- `TripRecordKey` là **surrogate key** do DDS sinh ra. Nó không phải khóa nghiệp vụ và không mang ý nghĩa ngoài DDS.

## 3. Phạm vi bản ghi vào Fact (Fact Scope)

| Quy tắc | Quyết định | Lý do |
|:---|:---|:---|
| Bản ghi nào được đưa vào? | **Toàn bộ 77.966.324 bản ghi** của 24 tệp | Bảo toàn grain "bản ghi nguồn"; đối soát được tổng số dòng với tệp |
| Pickup ngoài 2022–2023 (623 dòng) [`population_counts`] | Giữ, gắn `IsInStudyPeriod = FALSE` | Báo cáo mặc định lọc theo cờ; không xóa dữ liệu nguồn. Dũng đề xuất lọc ở ETL; điểm này còn mở ở [OD-10](logical_model_decisions.md) |
| Ngày ngoài phạm vi `DimDate` (2021-01-01 … 2024-12-31) | Khóa ngày trỏ thành viên `-1`; timestamp gốc vẫn giữ trong Fact | 593 dòng có pickup ngoài phạm vi (năm 2001–2014); 455 dòng có drop-off ngoài phạm vi, sớm nhất năm 1970 [`date_range_vs_dimdate`] |
| Dòng có `total_amount < 0` | Giữ, gắn `IsNegativeTotalAmount = TRUE` | Doanh thu ròng cần cả dòng âm. Cách đếm chuyến vẫn mở (§4) |
| Dòng trùng hoàn toàn (3 dòng) | Giữ | Không có căn cứ chắc chắn để coi là lỗi |

## 4. Hệ quả của grain đối với các chỉ số

### 4.1. Trip Count: chưa chốt (OD-01)

Phúc hiện định nghĩa M1 là `COUNT(FactTripKey)` ([metric_glossary.md](../phuc/metric_glossary.md) dòng 14), tức đếm mọi bản ghi. Trên grain "bản ghi nguồn" có ít nhất ba cách đếm khả dĩ:

| Định nghĩa | Công thức trên Fact | Ứng viên cặp đảo được đếm | Dòng âm không có cặp (74.390) | Hỗ trợ trong mô hình |
|:---|:---|:---|:---|:---|
| **Trip Record Count** (đúng M1 hiện hành) | `SUM(TripRecordCount)` | 2 lần | đếm | Có sẵn |
| **Operational Trip Count** | `SUM(TripRecordCount)` với `IsNegativeTotalAmount = FALSE` | **1 lần** (dòng dương còn lại) | không đếm | Có sẵn |
| **Net Trip Count** (loại cuốc bị hủy) | Loại cả hai dòng của ứng viên cặp đảo | 0 lần | không đếm | **Chưa có**: cần thêm cờ cấp cặp, ví dụ `IsInCandidateReversalPair`, tính được khi so sánh nhiều dòng |

- Loại dòng âm (Operational) **không** loại cuốc bị hủy: dòng dương gốc của nó vẫn được đếm một lần. Muốn coi cuốc bị hủy là "không có chuyến" thì phải dùng Net Trip Count.
- **Doanh thu không phụ thuộc lựa chọn này.** Total Revenue = `SUM(TotalAmount)` trên mọi dòng trong kỳ, nên cặp đảo tự triệt tiêu.
- **Tác động:**
  - Tử số của M1, và mẫu số của M10 (Revenue/Trip), M2 (khách trung bình) và các trung bình theo chuyến.
  - Mọi số đếm trong C1–C7, xếp hạng tuyến C7, hiệu ứng khối lượng ở E2, Revenue/Trip ở E3, tăng trưởng số chuyến ở E4.
  - Chênh lệch giữa Record và Operational là 632.589 dòng (0,81% tập `ALL_ROWS`).
- **Lộc không tự chốt.** Mô hình giữ đủ dữ liệu cho hai định nghĩa đầu; định nghĩa thứ ba cần bổ sung cờ nếu Phúc chọn.

### 4.2. Các chỉ số khác

1. **Reported Passengers (M2)** là tổng số khách *tài xế nhập*: NULL (3,43%) không cộng, 0 (1,73%) cộng 0.
2. **Mọi measure tiền tệ** cộng dồn được trên grain này. Tỷ lệ và trung bình (tip ratio, speed, revenue/trip) phải tính lại từ tử số và mẫu số ở thời điểm truy vấn.
3. **Tuyến đường (C7)** là thuộc tính của từng bản ghi: cặp có thứ tự `(PickupTaxiZoneKey, DropoffTaxiZoneKey)`. Có 49.932 cặp có thứ tự khác nhau [`distinct_ordered_routes`].

## 5. Vai trò thời gian và không gian trên mỗi bản ghi

Mỗi bản ghi mang **hai sự kiện**, đón và trả, nên Fact có sáu khóa vai trò (role-playing) tới ba chiều:

| Vai trò | Pickup | Drop-off | Chiều dùng chung |
|:---|:---|:---|:---|
| Ngày | `PickupDateKey` | `DropoffDateKey` | `DimDate` |
| Giờ trong ngày | `PickupTimeKey` | `DropoffTimeKey` | `DimTime` |
| Vùng | `PickupTaxiZoneKey` | `DropoffTaxiZoneKey` | `DimTaxiZone` |

Mặc định gán theo **pickup** (Quyết định 5 của Phúc). Mọi câu hỏi vẫn chọn được drop-off, vì cả hai khóa luôn có trên cùng một dòng (C4, C6, E5).

## 6. Lưu ý về thời gian nguồn

- Timestamp trong Parquet là **giờ địa phương New York, không kèm múi giờ**, nên thời lượng các cuốc vắt qua thời điểm đổi giờ có thể lệch ±1 giờ:
  - Đêm chuyển sang giờ mùa đông (06/11/2022, 05/11/2023): khung 01:00–01:59 xuất hiện hai lần.
  - Đêm chuyển sang giờ mùa hè (13/03/2022, 12/03/2023): khung 02:00–02:59 không tồn tại.
- 16.088 dòng có drop-off trước pickup, 31.516 dòng có thời lượng bằng 0 và 558 dòng dài hơn 24 giờ [`monthly`]. Các dòng này được giữ trong Fact. Chỉ số thời lượng và tốc độ loại chúng qua cờ `IsValidDuration` và `IsValidForSpeed` (xem [Fact logic §5](fact_yellow_taxi_trip_logical.md#5-thuộc-tính-dẫn-xuất)).
