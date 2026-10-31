# Kế hoạch công việc Phase 1: Trực

## Phạm vi phụ trách

**Đầu việc chính:** mô tả mô hình DDS tích hợp, lập đặc tả vật lý và kiểm tra các bảng, quan hệ có đáp ứng toàn bộ câu hỏi của dự án hay không.

**Thời lượng dự kiến:** khoảng 21 giờ (khoảng 20–22 giờ).

**Đầu ra chính:** mô tả DDS, từ điển/lược đồ dữ liệu vật lý và ma trận đối chiếu yêu cầu với lược đồ.

## Giới hạn phạm vi

Chỉ thực hiện tài liệu hóa và kiểm tra mô hình. Không bao gồm thiết kế hay xây dựng luồng xử lý dữ liệu, thiết kế tầng trung gian, tự động hóa, siêu dữ liệu nạp dữ liệu, ma trận kiểm thử ETL, nạp dữ liệu hoặc chạy kiểm thử.

## Các gói công việc

### A. Rà soát đầu vào mô hình (khoảng 3 giờ)

- Đọc đề bài, [Tổng quan Phase 1](phase1_overview.md), ma trận chỉ số đo/yêu cầu của Phúc, hồ sơ chung của Dũng và Lộc, cùng lược đồ sao logic.
- Ghi nhận mức hạt Fact đã thống nhất, mục đích từng chiều, các vai trò chiều, phân cấp và giả định.
- Ghi lại các lựa chọn còn mở hoặc điểm chưa thống nhất trước khi viết tài liệu cuối; giao rõ chủ sở hữu cần xem xét.

### B. Viết mô tả mô hình DDS (khoảng 4 giờ)

- Giải thích quy trình nghiệp vụ và mức hạt một dòng cho mỗi bản ghi chuyến đi nguồn.
- Mô tả mục đích, vai trò phân tích của bảng Fact chuyến đi và từng bảng chiều.
- Giải thích vai trò ngày, giờ và zone đón/trả; hướng tuyến; cách tổng hợp borough/zone.
- Mô tả các phân cấp/thuộc tính ngày-giờ, borough-zone, vendor, rate, payment, nhóm khách và cự ly.
- Viết rõ giả định và giới hạn nguồn để người đọc hiểu mục đích của từng bảng và quan hệ.

### C. Viết đặc tả vật lý DDS (khoảng 7 giờ)

Với từng bảng Fact và bảng chiều, ghi rõ:

- Tên bảng/cột, kiểu dữ liệu, độ dài/độ chính xác, đơn vị, cho phép NULL hay không, định nghĩa và ý nghĩa nghiệp vụ.
- Khóa chính, khóa ngoại, khóa nghiệp vụ của chiều và ý nghĩa khóa thay thế.
- Kiểu/độ chính xác phù hợp cho ngày, giờ, số đếm, dặm, tiền, mã và thuộc tính dẫn xuất.
- Khóa vai trò riêng cho ngày, giờ và zone đón/trả.
- Ý nghĩa của giá trị không xác định/NULL, gồm sự khác biệt với ID 264/265 hợp lệ nhưng không có vùng hình học.
- Các trường tùy chọn trong lược đồ 2022–2023, phân biệt không có dữ liệu với giá trị 0.

### D. Đối chiếu yêu cầu với lược đồ (khoảng 5 giờ)

Với từng yêu cầu cốt lõi C1–C8 và mở rộng E1–E5:

- Ghi tên measures, dimensions, vai trò chiều và phân cấp cần để trả lời.
- Mô tả đường nhóm dữ liệu và phép tính/mẫu số cần thiết theo định nghĩa metric của Phúc.
- Xác nhận hồ sơ nguồn 2022–2023 có các thuộc tính cần thiết.
- Ghi rõ khoảng trống, thuật ngữ chưa rõ hoặc giả định ảnh hưởng độ tin cậy; nêu chủ sở hữu cần giải quyết.
- Kiểm tra các trường hợp đặc biệt: quận đón/trả, cặp tuyến có hướng, tỷ lệ tiền tip, tốc độ, so sánh kỳ chưa đầy đủ và ID 264/265 không có vùng hình học.

### E. Tích hợp, rà soát và công bố (khoảng 2 giờ)

- Rà soát mô tả/đặc tả với các thành viên để bảo đảm nhất quán với lược đồ sao logic chung.
- Tổng hợp nhận xét, quản lý phiên bản gói mô hình vật lý, công bố ma trận bao phủ và danh sách quyết định còn mở.

## Đầu ra

- [dds_model_description.md](../../deliverables/phase1/truc/dds_model_description.md): mức hạt Fact, mục đích các bảng, quan hệ, vai trò, phân cấp, giả định và giới hạn nguồn.
- [dds_physical_spec.md](../../deliverables/phase1/truc/dds_physical_spec.md): bảng, cột, kiểu, độ chính xác, cho phép NULL hay không, khóa và định nghĩa.
- [physical_model_coverage.md](../../deliverables/phase1/truc/physical_model_coverage.md): đối chiếu C1–C8/E1–E5 với bảng, trường, vai trò và phép tính.
- [dds_model_decisions.md](../../deliverables/phase1/truc/dds_model_decisions.md): câu hỏi mô hình đã xử lý và còn mở, lý do cùng chủ sở hữu.

Sơ đồ tổng thể dùng lược đồ logic chung của Dũng và Lộc; không tạo sơ đồ vật lý trùng lặp.

## Tiêu chí nghiệm thu

- [x] Mô tả mô hình giải thích mục đích của từng bảng Fact/bảng chiều và cách quan hệ hỗ trợ phân tích.
- [x] Đặc tả vật lý ghi rõ trường, kiểu, độ chính xác, khóa, đơn vị và nullability.
- [x] Vai trò đón/trả và hướng tuyến được mô tả rõ.
- [x] Mỗi yêu cầu có đường đi trong lược đồ hoặc khoảng trống được ghi rõ.
- [x] Ma trận chỉ số đo đối chiếu định nghĩa của Phúc với hồ sơ nguồn 2022–2023 của Dũng/Lộc; các điểm chưa chốt được đánh dấu.
- [x] ID 264/265 được mô hình hóa mà không tạo polygon giả.
- [x] Gói đầu ra gồm mô tả/đặc tả mô hình, không có công việc pipeline hay nạp dữ liệu.

**Tình trạng rà soát:** các tài liệu đã được tích hợp trong thư mục dự án; chưa có xác nhận rà soát từ cả nhóm. Các quyết định OD-01–04, OD-07–09, C7-TIE và việc duyệt sơ đồ khái niệm vẫn cần chủ sở hữu xem xét; chi tiết nằm trong `dds_model_decisions.md`.

## Phụ thuộc và bàn giao

- **Từ Phúc:** định nghĩa nghiệp vụ đã thống nhất, công thức metric và ma trận yêu cầu.
- **Từ Dũng và Lộc:** hồ sơ chung, lược đồ sao logic và định nghĩa chiều có căn cứ từ nguồn.
- **Bàn giao cho nhóm:** mô tả mô hình, từ điển vật lý và kết quả đối chiếu yêu cầu với lược đồ.
