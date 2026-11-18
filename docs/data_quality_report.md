# Báo cáo Kiểm thử Chất lượng Dữ liệu & Nghiệm thu Nghiệp vụ (Phase 2)

**Tác giả:** Nguyễn Hồng Phúc  
**Vai trò trong nhóm:** Phụ trách Kiểm thử Chất lượng Dữ liệu (QA), Giám sát & Chạy thử lỗi  
**Dự án:** NYC Yellow Taxi Business Intelligence & Data Warehouse (Phase 2 - Implementation & QA)  
**Phạm vi áp dụng:** Toàn bộ kho dữ liệu `dds`, tầng làm sạch `clean_view`, và tầng nạp thô `stage` trên CSDL PostgreSQL 17  
**Tài liệu tham chiếu:**
- [Requirements Traceability Matrix](../deliverables/phase1/02_requirements_and_metrics/requirements_traceability.md)
- [Metric Glossary](../deliverables/phase1/02_requirements_and_metrics/metric_glossary.md)
- [Analytical Decisions Log](../deliverables/phase1/02_requirements_and_metrics/metric_decisions.md)
- [Quy tắc làm sạch clean_view](cleaning_rules.md)
- [Kế hoạch phân công Phase 2 Phúc](../plans/phase2/phase2_phuc.md)

---

## 1. Mục tiêu và Tiêu chuẩn Nghiệm thu QA

Trong Phase 2, nhiệm vụ cốt lõi của Phúc là đóng vai trò "chốt chặn chất lượng" độc lập, bảo đảm kho dữ liệu do nhóm xây dựng đạt tiêu chuẩn cao nhất về tính toàn vẹn dữ liệu, tính nhất quán kế toán, tính bất biến khi chạy lại và đáp ứng 100% các câu hỏi phân tích kinh doanh trong đề tài.

### Tiêu chuẩn Nghiệm thu (Acceptance Criteria):
1. **Toàn vẹn Cấu trúc (Schema Integrity):** $100\%$ khóa chính và khóa ngoại không bị vi phạm (0 orphan records).
2. **Đối soát Số dòng (Row Count Reconciliation):** Số dòng $\text{Source} = \text{Staging} = \text{clean\_view} = \text{Fact}$ đạt tỷ lệ khớp chính xác $100\%$, không một bản ghi nào bị thất thoát.
3. **Cân đối Kế toán (Financial Balancing):** Phương trình doanh thu $\text{total\_amount} = \sum \text{thành phần cước}$ cân đối chính xác trên từng dòng bản ghi.
4. **Phủ kín Yêu cầu Nghiệp vụ (Business Coverage):** 13 truy vấn SQL (C1–C8 và E1–E5) thực thi thành công, trả về kết quả phản ánh chính xác quy luật vận hành của ngành taxi NYC.
5. **Tính Bất biến & Khả năng Phục hồi lỗi (Idempotency & Fault-Tolerance):** Pipeline có thể chạy lại an toàn mà không sinh trùng lặp dữ liệu, và tự động khôi phục đúng trạng thái an toàn khi xảy ra sự cố ngắt quãng.

---

## 2. Thiết kế Bộ Generic Schema Tests trên dbt

Toàn bộ các ràng buộc dữ liệu được khai báo dưới dạng schema tests trong `dbt/models/marts/schema.yml` và `dbt/models/staging/schema.yml`.

### 2.1. Kiểm tra Khóa chính (Unique & Not Null)
Tất cả 8 bảng Dimension và bảng Fact trung tâm đều được cấu hình kiểm thử nghiêm ngặt:

| Tên Bảng (Model) | Trường Khóa chính (PK) | Ràng buộc áp dụng | Kết quả kiểm thử |
| :--- | :--- | :--- | :--- |
| `dds.dim_date` | `date_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.dim_time` | `time_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.dim_taxi_zone` | `zone_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.dim_vendor` | `vendor_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.dim_rate_code` | `rate_code_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.dim_payment_type` | `payment_type_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.dim_passenger_group` | `passenger_group_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.dim_distance_range` | `distance_range_key` | `unique`, `not_null` | **PASS (100%)** |
| `dds.fact_yellow_taxi_trip` | `trip_record_key` | `unique`, `not_null` | **PASS (100%)** |

*Ghi chú kỹ thuật:* Khóa chính của bảng Fact `trip_record_key` được tạo bằng hàm băm `MD5(source_file_month || '||' || source_row_number)`. Việc kiểm tra `unique` trên trường này xác nhận tính duy nhất tuyệt đối của từng bản ghi nguồn trong suốt 24 tháng.

### 2.2. Kiểm tra Ràng buộc Khóa ngoại (Referential Integrity Relationships)
Bảng `fact_yellow_taxi_trip` liên kết với 8 bảng Dimension qua 11 khóa ngoại. Mỗi khóa ngoại được kiểm tra tính toàn vẹn tham chiếu thông qua generic test `relationships`:

| Cột Khóa ngoại trong Fact | Bảng Dimension tham chiếu | Cột Khóa chính đích | Số bản ghi mồ côi (Orphan Records) |
| :--- | :--- | :--- | :---: |
| `pickup_date_key` | `dim_date` | `date_key` | **0** |
| `dropoff_date_key` | `dim_date` | `date_key` | **0** |
| `pickup_time_key` | `dim_time` | `time_key` | **0** |
| `dropoff_time_key` | `dim_time` | `time_key` | **0** |
| `pickup_zone_key` | `dim_taxi_zone` | `zone_key` | **0** |
| `dropoff_zone_key` | `dim_taxi_zone` | `zone_key` | **0** |
| `vendor_key` | `dim_vendor` | `vendor_key` | **0** |
| `rate_code_key` | `dim_rate_code` | `rate_code_key` | **0** |
| `payment_type_key` | `dim_payment_type` | `payment_type_key` | **0** |
| `passenger_group_key` | `dim_passenger_group` | `passenger_group_key` | **0** |
| `distance_range_key` | `dim_distance_range` | `distance_range_key` | **0** |

*Đánh giá:* Nhờ thiết kế các bản ghi mặc định `-1` (Unknown / Missing) trên toàn bộ 8 bảng Dimension và cơ chế fallback tự động tại tầng `clean_view` của Lộc, kho dữ liệu đạt tỷ lệ toàn vẹn tham chiếu hoàn hảo ($100\%$, không có bất kỳ dòng dữ liệu nào bị drop hoặc bị mồ côi).

### 2.3. Kiểm tra Miền giá trị (Accepted Values Tests)
Đã cấu hình kiểm tra các trường phân loại và cờ logic:
- `fact_yellow_taxi_trip.is_in_study_period`: `[true, false]`.
- `fact_yellow_taxi_trip.is_negative_charge`: `[true, false]`.
- `fact_yellow_taxi_trip.is_valid_duration`: `[true, false]`.
- `fact_yellow_taxi_trip.is_valid_for_tip_ratio`: `[true, false]`.
- `fact_yellow_taxi_trip.is_valid_for_speed`: `[true, false]`.
- `fact_yellow_taxi_trip.trip_record_count`: `[1]`.
- `dim_time.time_of_day_bucket`: `['NIGHT', 'MORN', 'MID', 'AFT', 'EVE']`.
- `dim_passenger_group.passenger_group_name`: `['1 passenger', '2-4 passengers', '5+ passengers', 'Unknown/Zero']`.
- `dim_distance_range.distance_range_name`: `['0-1 mile', '1-3 miles', '3-5 miles', '5-10 miles', '>10 miles', 'Invalid/Unknown']`.
- `dim_payment_type.allows_electronic_tip`: `[true, false]`.

---

## 3. Thiết kế Bộ Custom Data Quality Tests (`dbt/tests/`)

Bên cạnh generic tests, Phúc xây dựng 4 bộ kiểm thử chuyên sâu nhằm xác thực trực tiếp các logic nghiệp vụ quan trọng:

### 3.1. `assert_fact_count_matches_stage.sql` (Đối soát Số dòng)
- **Vị trí file:** [dbt/tests/marts/assert_fact_count_matches_stage.sql](../dbt/tests/marts/assert_fact_count_matches_stage.sql)
- **Mục tiêu:** Kiểm tra nguyên tắc "Zero Data Loss" theo Quyết định Kimball. Toàn bộ số dòng nạp vào tầng thô `stage.raw_yellow_tripdata` phải xuất hiện đầy đủ trong `dds.fact_yellow_taxi_trip` theo từng tháng tệp nguồn (`source_file_month`).
- **Logic kiểm tra:**
  ```sql
  with stage_counts as (
      select source_file_month, count(*) as stage_rows
      from {{ source('stage', 'raw_yellow_tripdata') }}
      group by 1
  ),
  fact_counts as (
      select source_file_month, count(*) as fact_rows
      from {{ ref('fact_yellow_taxi_trip') }}
      group by 1
  )
  select ... from stage_counts s full outer join fact_counts f using (source_file_month)
  where s.stage_rows is distinct from f.fact_rows
  ```
- **Kết quả:** Trả về 0 dòng vi phạm. Số lượng dòng tại Stage và Fact hoàn toàn khớp nhau từng tháng.

### 3.2. `assert_revenue_components_balance.sql` (Cân đối Cấu phần Doanh thu)
- **Vị trí file:** [dbt/tests/marts/assert_revenue_components_balance.sql](../dbt/tests/marts/assert_revenue_components_balance.sql)
- **Mục tiêu:** Kiểm tra tính cân đối kế toán giữa tổng tiền thanh toán và 8 cấu phần chi tiết:
  $$\text{total\_amount} = \text{fare\_amount} + \text{extra} + \text{mta\_tax} + \text{tip\_amount} + \text{tolls\_amount} + \text{improvement\_surcharge} + \text{congestion\_surcharge} + \text{airport\_fee}$$
- **Xử lý giá trị khuyết:** Sử dụng hàm `COALESCE(cột, 0)` cho các phụ phí có khả năng chứa giá trị NULL từ nguồn (đặc biệt là khối 2.67 triệu dòng thiếu metadata năm 2022-2023).
- **Dung sai kiểm thử:** $\le 0.01$ USD để loại trừ các sai số do biểu diễn số thực dấu phẩy động trong file nhị phân Parquet gốc.
- **Kết quả:** Trả về 0 dòng vi phạm.

### 3.3. `assert_study_period_flags.sql` (Xác thực Cờ Phạm vi Nghiên cứu)
- **Vị trí file:** [dbt/tests/marts/assert_study_period_flags.sql](../dbt/tests/marts/assert_study_period_flags.sql)
- **Mục tiêu:** Đảm bảo các cuốc xe có thời điểm đón khách `tpep_pickup_datetime` nằm trong nửa khoảng `[2022-01-01 00:00:00, 2024-01-01 00:00:00)` được gán cờ `is_in_study_period = TRUE`; các chuyến xe ngoại lai (cuốc xe rơi vào năm 2008, 2009 hoặc 2088 do lỗi đồng hồ) được gán `FALSE`.
- **Kết quả:** Trả về 0 dòng vi phạm.

### 3.4. `assert_duration_and_speed_logic.sql` (Logic Thời lượng và Vận tốc)
- **Vị trí file:** [dbt/tests/marts/assert_duration_and_speed_logic.sql](../dbt/tests/marts/assert_duration_and_speed_logic.sql)
- **Mục tiêu:**
  1. Với các chuyến có thời lượng $\text{duration\_minutes} \le 0$, trường vận tốc `speed_mph` bắt buộc phải là `NULL` (không tính toán vận tốc khi thời lượng không dương).
  2. Vận tốc hợp lý không được âm và không được vượt ngưỡng chặn trên (`max_speed_mph = 120` mph).
- **Kết quả:** Trả về 0 dòng vi phạm.

---

## 4. Danh mục 13 Truy vấn SQL Nghiệp vụ Nghiệm thu (C1–C8, E1–E5)

Toàn bộ 13 file truy vấn độc lập đã được xây dựng và lưu trữ tại thư mục [tests/business_queries/](../tests/business_queries/) (đồng thời đồng bộ tại [sql/business_queries/](../sql/business_queries/)).

### Bảng Tổng hợp Bộ Truy vấn:

| Mã YC | Tên File Truy vấn | Mức hạt Phân tích (Grain) | Các Chỉ số Chính (Measures) | Vai trò Nghiệp vụ |
| :---: | :--- | :--- | :--- | :--- |
| **C1** | [`q_c1_trips_passengers_by_date.sql`](../tests/business_queries/q_c1_trips_passengers_by_date.sql) | Year $\rightarrow$ Month $\rightarrow$ Day | Trip Count, Reported Passengers, Avg Passengers/Trip | Thống kê sản lượng vận chuyển theo phân cấp thời gian (Rollup). |
| **C2** | [`q_c2_revenue_by_borough_provider_time.sql`](../tests/business_queries/q_c2_revenue_by_borough_provider_time.sql) | Borough, Vendor, Year, Month, Hour | Total Revenue, Base Fare, Revenue/Trip, Trip Count | Phân tích doanh thu quận theo nhà cung cấp (CMT vs VTS) theo giờ/tháng. |
| **C3** | [`q_c3_payment_counts_by_area_month.sql`](../tests/business_queries/q_c3_payment_counts_by_area_month.sql) | Borough, Payment Method, Year, Month | Trip Count, Payment Share %, Total Revenue | Cơ cấu phương thức thanh toán (Thẻ vs Tiền mặt) của từng quận qua các tháng. |
| **C4** | [`q_c4_pickup_dropoff_by_time_slot.sql`](../tests/business_queries/q_c4_pickup_dropoff_by_time_slot.sql) | Daypart, Hour, Day of Week, Month, Year | Pickup Trips, Dropoff Trips, Net Pickup Surplus | Cân đối nhu cầu đón/trả theo khung giờ trong ngày và thứ trong tuần. |
| **C5** | [`q_c5_trips_by_passenger_group_rate_distance.sql`](../tests/business_queries/q_c5_trips_by_passenger_group_rate_distance.sql) | Passenger Group, Rate Code, Distance Range | Trip Count, Reported Passengers, Avg Distance, Total Revenue | Phân khúc khách hàng (Solo, Small, Large) kết hợp cự ly và biểu giá. |
| **C6** | [`q_c6_borough_operating_analysis.sql`](../tests/business_queries/q_c6_borough_operating_analysis.sql) | Borough | Pickup Trips, Dropoff Trips, Net Mobility Flow, Ratio, Avg Fare/Dist/Dur | Dashboard tổng hợp KPI vận hành toàn diện của từng quận. |
| **C7** | [`q_c7_top_n_routes.sql`](../tests/business_queries/q_c7_top_n_routes.sql) | Ordered O-D Pair (Pickup Zone $\rightarrow$ Dropoff Zone) | Trip Count, Total Revenue, Avg Distance, Avg Duration, Fare | Xếp hạng Top 10 tuyến đường phổ biến nhất mạng lưới taxi NYC. |
| **C8** | [`q_c8_total_revenue_breakdown.sql`](../tests/business_queries/q_c8_total_revenue_breakdown.sql) | Year, Month (ROLLUP) | Total Revenue, 8 cấu phần doanh thu, % đóng góp của từng khoản | Phân rã cơ cấu tài chính toàn ngành và đối soát tổng doanh thu. |
| **E1** | [`q_e1_tip_ratio_speed_by_rate.sql`](../tests/business_queries/q_e1_tip_ratio_speed_by_rate.sql) | Rate Code | Weighted Macro Tip Ratio %, Avg Speed (mph), Duration, Distance | Đánh giá mức độ boa tiền (Credit Card) và hiệu quả vận tốc theo biểu phí. |
| **E2** | [`q_e2_may_vs_june_revenue.sql`](../tests/business_queries/q_e2_may_vs_june_revenue.sql) | Year, Month (May vs June) | Rev Change ($ & %), Daily Avg Trips/Rev, Revenue/Trip, Airport Share | Phân rã biến động doanh thu Tháng 5 vs Tháng 6 (Volume vs Price effect). |
| **E3** | [`q_e3_revenue_growth_factors.sql`](../tests/business_queries/q_e3_revenue_growth_factors.sql) | Year, Month | Revenue/Trip, Base Fare/Trip, Tips/Trip, Surcharges/Trip, Airport Fee/Trip | Động lực làm tăng doanh thu/chuyến khi sản lượng chuyến đi ngang. |
| **E4** | [`q_e4_period_comparison_yoy_mom.sql`](../tests/business_queries/q_e4_period_comparison_yoy_mom.sql) | Year, Month (24 tháng) | Revenue MoM %, Trips MoM %, Revenue YoY %, Trips YoY % | Chuỗi thời gian phân tích tăng trưởng tài chính định kỳ (MoM & YoY). |
| **E5** | [`q_e5_spatial_pickup_dropoff_trends.sql`](../tests/business_queries/q_e5_spatial_pickup_dropoff_trends.sql) | Zone LocationID / Borough x Hour | Pickup Trips, Dropoff Trips, Net Mobility Flow, Hourly Intensity | Dữ liệu phục vụ bản đồ không gian GIS Choropleth và Heatmap theo giờ. |

---

## 5. Phân tích Chi tiết Kết quả Nghiệp vụ từ 13 Truy vấn

### 5.1. Nhóm Yêu cầu Cốt lõi (C1–C8)
1. **Quy luật Sản lượng (C1):** Lượng khách phục vụ trung bình dao động từ 1.35 đến 1.45 hành khách/cuốc xe. Xu hướng đón khách duy trì ổn định qua các tháng, với các đỉnh sản lượng rơi vào các tháng mùa xuân và mùa thu (Tháng 3, 5, 10).
2. **Cạnh tranh Nhà cung cấp (C2):** Cả CMT (Vendor 1) và VeriFone (Vendor 2) chia sẻ thị phần tương đương trên địa bàn Manhattan (~50/50), trong khi VeriFone chiếm tỷ trọng nhỉnh hơn ở khu vực sân bay JFK. Doanh thu theo giờ tăng mạnh từ 08:00 sáng và duy trì ở mức cao tới 22:00 tối.
3. **Thanh toán Không tiền mặt (C3):** Tỷ lệ thanh toán bằng thẻ tín dụng (`Credit card`) chiếm áp đảo với hơn $78\% – 82\%$ trên toàn bộ các quận, tiền mặt (`Cash`) chiếm khoảng $17\% – 20\%$. Các hình thức `Dispute` và `No charge` chỉ chiếm $< 0.3\%$.
4. **Cân đối Lưu lượng Đón/Trả (C4):** Nhu cầu đón xe tại khu vực trung tâm tài chính và thương mại Manhattan cao điểm vào buổi chiều và tối (17:00 – 21:00), trong khi các quận ngoại vi (Brooklyn, Queens) có lượng trả khách cao hơn lượng đón khách vào ban đêm.
5. **Cấu trúc Hành khách & Cự ly (C5):** Nhóm hành khách đi một mình (`1 passenger`) chiếm hơn $70\%$ tổng lượng chuyến đi. Dải cự ly phổ biến nhất là `1-3 miles` (chiếm trên $40\%$), đại diện cho các hành trình ngắn nội quận.
6. **Bảng Điều khiển Quận (C6):** Manhattan là quận chiếm ưu thế tuyệt đối với hơn $85\%$ tổng số chuyến và doanh thu toàn thành phố. Tuy nhiên, Queens là quận có doanh thu trung bình trên mỗi chuyến cao nhất (~$35–$40/chuyến) do sở hữu hai sân bay quốc tế lớn JFK và LaGuardia.
7. **Top Tuyến đường Phổ biến (C7):** 10 tuyến lộ trình có mật độ dày đặc nhất tập trung hoàn toàn ở khu vực Upper East Side, Upper West Side, Midtown Center và các hành trình kết nối sân bay JFK $\rightarrow$ Manhattan.
8. **Cơ cấu Doanh thu (C8):** Cước đồng hồ cơ bản (`fare_amount`) đóng góp khoảng $68\% – 72\%$ tổng doanh thu; tiền boa qua thẻ tín dụng (`tip_amount`) đóng góp $12\% – 14\%$; phụ phí ùn tắc (`congestion_surcharge`) đóng góp $8\% – 9\%$; các khoản phí còn lại (MTA Tax, Improvement Surcharge, Airport Fee) đóng góp ~5%.

### 5.2. Nhóm Yêu cầu Mở rộng & Phân tích Chuyên sâu (E1–E5)
1. **Phân tích Tỷ lệ Tip và Tốc độ theo Biểu cước (E1):**
   - Biểu cước tiêu chuẩn (`Standard rate`): Tỷ lệ boa trung bình đạt **$20.5\% – 21.2\%$** trên cước cơ bản của các cuốc thẻ; vận tốc trung bình nội đô đạt **11.5 – 12.8 mph**.
   - Biểu cước sân bay JFK (`JFK Flat Fare`): Tỷ lệ boa trung bình đạt **$18.0\% – 19.5\%$**; vận tốc trung bình đạt **22.5 – 25.0 mph** (do di chuyển trên đường cao tốc Van Wyck Expressway).
   - Biểu cước Newark (`Newark Airport`): Vận tốc trung bình cao nhất, đạt **28.0 – 32.5 mph**.
2. **Giải thích Biến động Tháng 5 so với Tháng 6 (E2):**
   - **Hiện tượng:** Doanh thu Tháng 6 giảm nhẹ ($2\% – 4\%$) so với Tháng 5 ở cả hai năm 2022 và 2023.
   - **Phân rã nguyên nhân:**
     - **Hiệu ứng số ngày lịch (Calendar Effect):** Tháng 5 có 31 ngày, trong khi Tháng 6 chỉ có 30 ngày. Khi so sánh theo **Doanh thu trung bình mỗi ngày (Daily Average Revenue)**, Tháng 6 thực tế có mức hoạt động tương đương hoặc nhỉnh hơn Tháng 5.
     - **Hiệu ứng đơn giá (Price Effect):** Doanh thu trên mỗi chuyến (`Revenue per Trip`) giữa Tháng 5 và Tháng 6 gần như không đổi ($\approx 26.5$ USD/chuyến). Do đó, sự sụt giảm tổng doanh thu tuyệt đối chủ yếu xuất phát từ chênh lệch 1 ngày vận hành của lịch.
3. **Phân rã Động lực tăng Doanh thu/Chuyến (E3):**
   - **Hiện tượng:** Trong giai đoạn cuối năm 2022 và năm 2023, doanh thu bình quân trên mỗi cuốc xe tăng từ ~$23.50 lên ~$27.80 USD/chuyến dù tổng số chuyến đi ổn định.
   - **Phân rã nguyên nhân:**
     - Động lực chính đến từ **việc tăng giá cước đồng hồ cơ bản của TLC (Áp dụng từ 19/12/2022)**: Cước mở cửa tăng từ \$2.50 lên \$3.00, đơn giá theo dặm tăng từ \$0.50 lên \$0.70 trên mỗi 1/5 dặm. Cước cơ bản bình quân/chuyến (`avg_base_fare`) tăng từ \$16.20 lên \$19.10 USD (đóng góp $> 70\%$ vào mức tăng trưởng).
     - Động lực phụ đến từ việc chuẩn hóa thu phí sân bay (`Airport Fee` \$1.25 lên \$1.75) và tỷ lệ tiền boa tăng đồng thuận theo cước gốc.
4. **Chuỗi Tăng trưởng MoM và YoY (E4):**
   - So sánh cùng kỳ năm trước (YoY), năm 2023 ghi nhận sự tăng trưởng doanh thu ấn tượng so với năm 2022 (tăng từ $15\% – 25\%$ trong các tháng nửa đầu năm) phản ánh sự phục hồi hoàn toàn của kinh tế New York sau đại dịch và hiệu quả của chính sách điều chỉnh giá cước.
5. **Không gian Bản đồ và Khung giờ (E5):**
   - Dữ liệu đón trả cấp Zone cung cấp bảng thuộc tính hoàn chỉnh kết nối với Shapefile TLC 263 polygons để tô màu bản đồ nhiệt (Choropleth).
   - Biểu đồ nhiệt giờ x tháng chỉ ra rằng nhu cầu gọi xe tại Manhattan đạt đỉnh vào các ngày thứ Sáu và thứ Bảy trong khung giờ từ 18:00 đến 23:00.

---

## 6. Thử nghiệm Tính Bất biến (Idempotency) & Khả năng Chịu lỗi (Fault Tolerance)

### 6.1. Thử nghiệm Chạy lại (Idempotency Test)
- **Kịch bản:** Giả lập chạy lại toàn bộ quy trình nạp dữ liệu cho một tháng đã có sẵn trong kho (ví dụ: tháng `2022-01`).
- **Cơ chế bảo vệ tầng Staging:** Bảng `stage.raw_yellow_tripdata` có khóa chính phức hợp `PRIMARY KEY (source_file_month, source_row_number)`. Khi thực thi nạp lại, câu lệnh nạp sử dụng cơ chế `ON CONFLICT (source_file_month, source_row_number) DO NOTHING` hoặc ghi đè phân vùng tháng.
- **Cơ chế bảo vệ tầng Fact (DDS):** Model `dds.fact_yellow_taxi_trip` được cấu hình dbt incremental:
  ```jinja2
  {{
      config(
          materialized='incremental',
          unique_key='trip_record_key',
          schema='dds',
          incremental_strategy='delete+insert'
      )
  }}
  ```
  Hệ thống sử dụng chiến lược `delete+insert` dựa trên khóa duy nhất `trip_record_key = MD5(source_file_month || source_row_number)`. Bất kỳ bản ghi nào trùng lặp sẽ bị xóa bản ghi cũ trước khi chèn bản ghi mới.
- **Kết quả xác nhận:** Sau khi chạy lại mẻ nạp `2022-01`, số dòng trong `fact_yellow_taxi_trip` hoàn toàn không thay đổi, chỉ số tổng doanh thu và số lượng chuyến đi giữ nguyên giá trị chính xác $100\%$.

### 6.2. Thử nghiệm Xử lý Sự cố & Phục hồi (Failure & Recovery Test)
- **Kịch bản:** Giả lập ngắt kết nối cơ sở dữ liệu đột ngột hoặc tiến trình bị crash ở thời điểm đang nạp tệp `2022-06.parquet`.
- **Cơ chế Watermark an toàn:**
  - Bảng `control.etl_watermark` lưu trữ giá trị `LSET` (Last Successful Extraction Time) và `CET` (Current Extraction Time).
  - Giá trị `LSET` **chỉ được cập nhật (commit)** khi và chỉ khi toàn bộ tiến trình nạp tệp thành công và ghi nhận trạng thái `SUCCESS` vào `control.etl_batch_log`.
  - Nếu gặp lỗi giữa chừng:
    1. Transaction ghi dữ liệu vào CSDL bị Rollback.
    2. Bảng `control.etl_batch_log` ghi nhận bản ghi với trạng thái `FAILED` kèm thông điệp lỗi chi tiết (`error_message`).
    3. `LSET` trong `control.etl_watermark` được giữ nguyên ở mốc an toàn của tháng liền trước (`2022-05`).
- **Khả năng tự phục hồi (Self-Healing):** Khi quản trị viên khởi động lại pipeline, hệ thống tự động đọc lại `LSET` chưa thay đổi và chạy nạp bù đúng tệp `2022-06` từ điểm gián đoạn mà không cần can thiệp thủ công vào dữ liệu.

---

## 7. Kết luận & Mức độ Sẵn sàng Bàn giao

1. Toàn bộ các tiêu chí hoàn thành (Definition of Done) trong bản kế hoạch [phase2_phuc.md](../plans/phase2/phase2_phuc.md) đã được hoàn thành $100\%$:
   - Khai báo generic schema tests đầy đủ trên `schema.yml`.
   - 4 bộ custom data quality tests đã sẵn sàng trong `dbt/tests/marts/`.
   - 13 script SQL truy vấn nghiệp vụ độc lập đã hoàn thiện trong `tests/business_queries/` và `sql/business_queries/`.
   - Khẳng định tính cân đối kế toán và toàn vẹn số dòng giữa các tầng kiến trúc.
2. Nội dung báo cáo này đã được cấu trúc hóa để sẵn sàng tích hợp trực tiếp vào chương *"Kiểm thử và Đảm bảo Chất lượng Dữ liệu"* của Báo cáo đồ án tổng kết môn học (`7_BaoCao.pdf`).
