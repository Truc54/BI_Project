# Kế hoạch Phân công: Nguyễn Hồng Phúc

## 1. Trách nhiệm chính
* Phụ trách **Kiểm thử chất lượng dữ liệu (QA), Giám sát & Chạy thử lỗi**: Xây dựng bộ kiểm thử tự động trên dbt, đối soát số dòng giữa các tầng (Source = Staging = Fact), viết và thực thi 13 truy vấn SQL nghiệm thu cho các yêu cầu C1–C8 và E1–E5, thử nghiệm kịch bản khi pipeline gặp lỗi.

---

## 2. Đầu vào (Inputs)
* Kho dữ liệu DDS do Dũng hoàn thiện (`dds.fact_yellow_taxi_trip` và 8 bảng Dimension).
* Bảng log nạp `control.etl_batch_log` do Trực cung cấp.
* Báo cáo Phase 1 [report.pdf](file:///c:/Users/truct/source/BI_Project/report.pdf) (Mục 5: Đối chiếu yêu cầu phân tích).
* Ma trận yêu cầu và chỉ số Phase 1: [requirements_traceability.md](file:///c:/Users/truct/source/BI_Project/deliverables/phase1/02_requirements_and_metrics/requirements_traceability.md) và [metric_glossary.md](file:///c:/Users/truct/source/BI_Project/deliverables/phase1/02_requirements_and_metrics/metric_glossary.md).

---

## 3. Các đầu việc cần làm (Tasks)

### A. Xây dựng Bộ dbt Generic Schema Tests
Khai báo cấu hình test trong các file `schema.yml`:
1. **Kiểm tra Khóa chính (Unique & Not Null):** Đảm bảo tất cả khóa chính của 8 bảng Dimension và bảng Fact không bao giờ bị trùng lặp hoặc chứa giá trị NULL.
2. **Kiểm tra Ràng buộc Khóa ngoại (Relationships):** Ràng buộc mọi khóa ngoại trong bảng Fact phải tồn tại trong bảng Dimension tương ứng (tuyệt đối không có bản ghi mồ côi - 0 orphan records).
3. **Kiểm tra Miền giá trị (Accepted Values):** Kiểm tra các trường danh mục và cờ boolean (`is_in_study_period`).

### B. Xây dựng Bộ Custom Data Quality Tests (`dbt/tests/`)
Viết 4 file SQL test nghiệp vụ nâng cao:
1. **`assert_fact_count_matches_stage.sql` (Đối soát số dòng):** So sánh tổng số dòng giữa `stage.raw_yellow_tripdata` và `dds.fact_yellow_taxi_trip` theo từng tháng. Kết quả mong đợi: Khớp chính xác $100\%$, không bị thất thoát bản ghi nào.
2. **`assert_revenue_components_balance.sql` (Cân đối doanh thu):** Kiểm tra tính cân đối của phương trình: $\text{total\_amount} = \text{fare\_amount} + \text{extra} + \dots + \text{airport\_fee}$.
3. **`assert_study_period_flags.sql`:** Xác nhận các chuyến đón trong giai đoạn 2022–2023 có `is_in_study_period = TRUE`, các chuyến ngoài giai đoạn này có giá trị `FALSE`.
4. **`assert_duration_and_speed_logic.sql`:** Đảm bảo các cuốc có thời lượng $\le 0$ thì vận tốc phải là NULL.

### C. Xây dựng Bộ 13 Truy vấn SQL Nghiệp vụ Xác thực (C1–C8, E1–E5)
Viết 13 file script SQL trong thư mục `tests/business_queries/` chạy trực tiếp trên kho `dds`:
* `q_c1_trips_passengers_by_date.sql`: Chuyến và hành khách theo ngày, tháng, năm.
* `q_c2_revenue_by_borough_provider_time.sql`: Doanh thu theo quận, nhà cung cấp và thời điểm.
* `q_c3_payment_counts_by_area_month.sql`: Số chuyến theo hình thức thanh toán ở từng quận qua các tháng.
* `q_c4_pickup_dropoff_by_time_slot.sql`: Số chuyến đón/trả theo khung giờ, thứ trong tuần, tháng.
* `q_c5_trips_by_passenger_group_rate_distance.sql`: Số chuyến theo nhóm khách, loại biểu phí, cự ly.
* `q_c6_borough_operating_analysis.sql`: Tổng hợp KPI hoạt động theo từng quận.
* `q_c7_top_n_routes.sql`: Top N lộ trình phổ biến nhất.
* `q_c8_total_revenue_breakdown.sql`: Tổng doanh thu và chi tiết các cấu phần.
* `q_e1_tip_ratio_speed_by_rate.sql`: So sánh tỷ lệ tiền tip trung bình và vận tốc theo loại biểu phí.
* `q_e2_may_vs_june_revenue.sql`: Biến động doanh thu Tháng 5 so với Tháng 6 và nguyên nhân.
* `q_e3_revenue_growth_factors.sql`: Yếu tố làm tăng doanh thu/cuốc khi lượng chuyến ổn định.
* `q_e4_period_comparison_yoy_mom.sql`: So sánh doanh thu và số lượng chuyến cùng kỳ (YoY, MoM).
* `q_e5_spatial_pickup_dropoff_trends.sql`: Tổng hợp đón/trả phục vụ trực quan hóa bản đồ không gian và xu hướng giờ.

### D. Thử nghiệm Xử lý Lỗi & Tính Bất biến (Idempotency)
1. **Kiểm tra chạy lại (Idempotency Test):** Chạy lại pipeline nạp một tháng đã có sẵn, xác nhận bảng Fact không bị nhân đôi dữ liệu.
2. **Kiểm tra khi bị ngắt kết nối (Failure & Recovery Test):** Giả lập lỗi giữa chừng, kiểm tra xem `control.etl_watermark` có giữ nguyên LSET an toàn để chạy bù hay không.

### E. Viết Báo cáo Kiểm thử Phase 2
* Lập bảng thống kê kết quả chạy test dbt (Pass/Fail) và thời gian thực thi của 13 query.
* Viết nội dung chương "Kiểm thử và Đảm bảo Chất lượng Dữ liệu" trong báo cáo `7_BaoCao.pdf`.

---

## 4. Đầu ra bàn giao (Outputs)
* Khai báo test trong `schema.yml`.
* 4 script custom test trong `dbt/tests/`.
* 13 script SQL truy vấn nghiệp vụ: `tests/business_queries/q_c1.sql` đến `q_e5.sql`.
* Báo cáo kết quả kiểm thử và đối soát dữ liệu: `docs/data_quality_report.md`.

---

## 5. Tiêu chí hoàn thành (Done Definition)
* Lệnh `dbt test` chạy thành công (Pass $100\%$, 0 failure).
* 13 câu SQL chạy ra kết quả đúng logic nghiệp vụ trên kho `dds`.
* Báo cáo kiểm thử hoàn chỉnh sẵn sàng đưa vào báo cáo tổng kết nộp bài.
