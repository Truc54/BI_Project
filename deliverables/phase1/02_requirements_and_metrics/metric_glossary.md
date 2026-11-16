# Metric Glossary (Phúc - Phase 1)

## 1. Mục đích
Tài liệu này định nghĩa từ điển các chỉ số đo lường (Metrics Glossary) trong toàn bộ dự án BI. Mỗi chỉ số được chuẩn hóa về mặt công thức toán học, đơn vị đo lường, mẫu số tính toán, tính chất tổng hợp (Aggregation Behavior), quy tắc xử lý dữ liệu ngoại lệ/khuyết thiếu và các lưu ý/hạn chế từ nguồn dữ liệu thực tế TLC Yellow Taxi (2022–2023).

---

## 2. Từ điển Chỉ số Đo lường Chi tiết

### M1. Số lượng chuyến taxi (Trip Count)
- **Tên hiển thị:** `Trip Count` / `Số lượng chuyến đi`
- **Ý nghĩa nghiệp vụ:** Đo lường tổng số lượt chuyến taxi Yellow Cab hợp lệ đã hoàn thành trong khoảng thời gian và phạm vi địa lý xác định.
- **Công thức:** 
  $$\text{Trip Count} = \sum 1 = \text{COUNT}(\text{FactTripKey})$$
- **Đơn vị đo:** Chuyến (trips)
- **Tính chất tổng hợp:** Hoàn toàn cộng dồn (Fully Additive) qua mọi chiều phân tích (Thời gian, Địa lý, Nhà cung cấp, Phương thức thanh toán...).
- **Xử lý ngoại lệ / Missing:** 
  - Đếm toàn bộ các bản ghi hợp lệ trong `FactYellowTaxiTrip`.
  - Không giả định mỗi bản ghi là một chuyến xe duy nhất tuyệt đối (unique trip) trừ khi đã có quy tắc deduplication được thống nhất.
- **Hạn chế từ nguồn:** Bản ghi chuyến đi do hệ thống thiết bị trên xe (In-vehicle Taximeter / TPEP) tự động ghi nhận khi đồng hồ bật/tắt.

---

### M2. Số lượng hành khách ghi nhận (Total Reported Passengers)
- **Tên hiển thị:** `Reported Passenger Count` / `Số lượng hành khách ghi nhận`
- **Ý nghĩa nghiệp vụ:** Tổng số lượng hành khách do tài xế ghi nhận trên đồng hồ tính cước.
- **Công thức:**
  $$\text{Reported Passengers} = \sum \text{passenger\_count}$$
- **Đơn vị đo:** Người (passengers)
- **Tính chất tổng hợp:** Hoàn toàn cộng dồn (Fully Additive).
- **Mẫu số tính trung bình:**
  $$\text{Avg Passengers per Trip} = \frac{\sum \text{passenger\_count}}{\text{Trip Count}}$$
- **Xử lý ngoại lệ / Missing:**
  - Nếu `passenger_count` bị `NULL` hoặc `= 0`: Trong dữ liệu thực tế của TLC, nhiều chuyến có `passenger_count = 0` (do tài xế không bấm số khách trên đồng hồ). Khi tính tổng số khách, chỉ cộng các giá trị hợp lệ $\ge 1$, hoặc quy ước ghi nhận riêng nhóm không xác định.
  - Giá trị $> 9$: Coi là ngoại lệ (outlier), cần được kiểm tra trong giai đoạn data profiling.
- **Hạn chế từ nguồn:** Đây là số lượng do tài xế **tự bấm bằng tay (driver-reported)**, không phải số lượng hành khách độc nhất (unique riders) và có thể có sai số do tài xế bỏ qua không nhập.

---

### M3. Tổng doanh thu (Total Revenue)
- **Tên hiển thị:** `Total Revenue` / `Tổng doanh thu`
- **Ý nghĩa nghiệp vụ:** Tổng số tiền hành khách thanh toán cho các dịch vụ taxi Yellow Cab, bao gồm cước cơ bản và toàn bộ các khoản thuế, phí, tiền boa qua thẻ.
- **Công thức:**
  $$\text{Total Revenue} = \sum \text{total\_amount}$$
- **Cấu phần chi tiết:**
  $$\text{total\_amount} = \text{fare\_amount} + \text{extra} + \text{mta\_tax} + \text{tip\_amount} + \text{tolls\_amount} + \text{improvement\_surcharge} + \text{congestion\_surcharge} + \text{Airport\_fee}$$
- **Đơn vị đo:** USD ($)
- **Tính chất tổng hợp:** Hoàn toàn cộng dồn (Fully Additive).
- **Xử lý ngoại lệ / Missing:**
  - Các giá trị âm (`total_amount < 0`): Đại diện cho các giao dịch hoàn tiền, hủy chuyến hoặc tranh chấp (Dispute/Void). Cần giữ nguyên trong Fact để bảo toàn tính cân đối kế toán, nhưng cần lọc riêng khi phân tích đơn giá chuyến đi thông thường.
  - Giá trị `= 0`: Chuyến xe miễn phí (No Charge) hoặc sự cố đồng hồ.
- **Hạn chế từ nguồn (Cực kỳ quan trọng):** Theo đặc tả chính thức của TLC, `total_amount` **KHÔNG bao gồm tiền boa bằng tiền mặt (cash tips)** vì tài xế nhận tiền mặt trực tiếp không qua đồng hồ. Do đó, tổng doanh thu thực tế của ngành có thể cao hơn con số ghi nhận trên hệ thống.

---

### M4. Tiền cước đồng hồ cơ bản (Fare Amount)
- **Tên hiển thị:** `Fare Amount` / `Cước đồng hồ cơ bản`
- **Ý nghĩa nghiệp vụ:** Tiền cước chuyến đi tính theo thời gian và khoảng cách di chuyển được quy định bởi biểu phí của TLC (chưa bao gồm thuế, phí và tip).
- **Công thức:**
  $$\text{Fare Amount} = \sum \text{fare\_amount}$$
- **Đơn vị đo:** USD ($)
- **Tính chất tổng hợp:** Hoàn toàn cộng dồn (Fully Additive).
- **Xử lý ngoại lệ:** Giá trị âm thể hiện hoàn cước; giá trị cực lớn cần đối chiếu cự ly.

---

### M5. Tiền boa ghi nhận (Recorded Tip Amount)
- **Tên hiển thị:** `Recorded Tip Amount` / `Tiền boa ghi nhận`
- **Ý nghĩa nghiệp vụ:** Tổng số tiền boa (tip) được ghi nhận qua hệ thống máy quẹt thẻ trên xe.
- **Công thức:**
  $$\text{Recorded Tip Amount} = \sum \text{tip\_amount}$$
- **Đơn vị đo:** USD ($)
- **Tính chất tổng hợp:** Hoàn toàn cộng dồn (Fully Additive).
- **Hạn chế từ nguồn:** Trường `tip_amount` tự động ghi nhận khi thanh toán qua thẻ tín dụng (`payment_type = 1`). Khi khách trả tiền mặt (`payment_type = 2`), trường này hầu như luôn bằng 0.

---

### M6. Tỷ lệ tiền boa trung bình (Average Tip Ratio)
- **Tên hiển thị:** `Avg Tip Ratio` / `Tỷ lệ tiền boa trung bình`
- **Ý nghĩa nghiệp vụ:** Đo lường mức độ hào phóng của khách hàng đối với dịch vụ taxi theo từng loại biểu phí hoặc khu vực.
- **Phương pháp tính toán (2 cách tiếp cận chuẩn):**
  - **Cách 1 (Tổng hợp vĩ mô - Weighted Aggregate Ratio - Khuyến nghị cho báo cáo cấp độ tổng thể):**
    $$\text{Macro Tip Ratio} = \frac{\sum_{\text{Credit Card}} \text{tip\_amount}}{\sum_{\text{Credit Card}} \text{fare\_amount}}$$
  - **Cách 2 (Trung bình cấp độ chuyến đi - Mean Trip-level Tip Ratio - Dùng cho phân phối hành vi):**
    $$\text{Trip Tip Ratio}_i = \frac{\text{tip\_amount}_i}{\text{fare\_amount}_i}$$
    $$\text{Average Trip Tip Ratio} = \frac{1}{N_{\text{valid}}} \sum_{i=1}^{N_{\text{valid}}} \text{Trip Tip Ratio}_i$$
- **Đơn vị đo:** Tỷ lệ phần trăm (%)
- **Tính chất tổng hợp:** Không thể cộng dồn (Non-Additive). Bắt buộc phải tính toán tại thời điểm truy vấn từ các thành phần tổng.
- **Quy tắc mẫu số & Điều kiện lọc bắt buộc:**
  1. Chỉ áp dụng cho các chuyến thanh toán bằng thẻ (`payment_type = 1` - Credit Card).
  2. Mẫu số `fare_amount` phải $> 0$ (loại trừ trường hợp cước $= 0$ để tránh lỗi chia cho 0).
  3. Loại trừ các giá trị vô lý: $\text{Trip Tip Ratio} > 200\%$ hoặc âm.
- **Hạn chế từ nguồn:** Tuyệt đối không tính chỉ số này trên toàn bộ tập dữ liệu gộp cả tiền mặt, vì điều đó sẽ làm sai lệch mẫu số (kéo tụt tỷ lệ tip trung bình xuống do hàng triệu chuyến tiền mặt có tip = 0 trên hệ thống).

---

### M7. Thời gian di chuyển (Trip Duration)
- **Tên hiển thị:** `Trip Duration` / `Thời gian hành trình`
- **Ý nghĩa nghiệp vụ:** Tổng thời gian từ lúc khách lên xe đến khi kết thúc chuyến đi.
- **Công thức:**
  $$\text{Duration (seconds)} = \text{DATEDIFF}(\text{second}, \text{tpep\_pickup\_datetime}, \text{tpep\_dropoff\_datetime})$$
  $$\text{Duration (minutes)} = \frac{\text{Duration (seconds)}}{60}$$
  $$\text{Duration (hours)} = \frac{\text{Duration (seconds)}}{3600}$$
- **Đơn vị đo:** Phút (minutes) hoặc Giờ (hours)
- **Tính chất tổng hợp:** Bán cộng dồn hoặc phi cộng dồn khi xem trung bình:
  $$\text{Avg Duration} = \frac{\sum \text{Duration}}{\text{Trip Count}}$$
- **Xử lý ngoại lệ / Missing:**
  - $\text{Duration} \le 0$: Lỗi ghi nhận thời gian hoặc đồng hồ bị chỉnh lùi $\rightarrow$ Không hợp lệ để tính vận tốc.
  - $\text{Duration} > 24$ giờ: Chuyến đi bất thường hoặc tài xế quên đóng cuốc $\rightarrow$ Đưa vào nhóm cảnh báo outlier.

---

### M8. Cự ly chuyến đi (Trip Distance)
- **Tên hiển thị:** `Trip Distance` / `Khoảng cách chuyến đi`
- **Ý nghĩa nghiệp vụ:** Tổng quãng đường xe lăn bánh phục vụ hành khách, đo bằng máy đo cước (Taximeter).
- **Công thức:**
  $$\text{Total Distance} = \sum \text{trip\_distance}$$
  $$\text{Avg Distance per Trip} = \frac{\sum \text{trip\_distance}}{\text{Trip Count}}$$
- **Đơn vị đo:** Dặm (miles). (1 dặm $\approx 1.60934$ km).
- **Tính chất tổng hợp:** Hoàn toàn cộng dồn (Fully Additive) đối với tổng cự ly; phi cộng dồn đối với cự ly trung bình.
- **Xử lý ngoại lệ:** 
  - `trip_distance = 0` nhưng `fare_amount > 0`: Khách đổi ý hủy chuyến tại chỗ, cước chờ thời gian, hoặc hỏng cảm biến công tơ mét.
  - `trip_distance > 500` dặm: Outlier.

---

### M9. Vận tốc di chuyển trung bình (Average Speed)
- **Tên hiển thị:** `Avg Speed` / `Vận tốc trung bình`
- **Ý nghĩa nghiệp vụ:** Tốc độ di chuyển trung bình của chuyến taxi trong hành trình.
- **Công thức:**
  - Cấp độ chuyến đi $i$:
    $$\text{Speed}_i (\text{mph}) = \frac{\text{trip\_distance}_i}{\text{Duration}_i (\text{hours})}$$
  - Cấp độ tổng hợp (Aggregate Speed - Khuyến nghị cho KPI nhóm/vùng):
    $$\text{Average Speed} = \frac{\sum \text{trip\_distance}}{\sum \text{Duration (hours)}}$$
- **Đơn vị đo:** Dặm/giờ (mph - Miles Per Hour).
- **Tính chất tổng hợp:** Phi cộng dồn (Non-Additive).
- **Quy tắc lọc dữ liệu hợp lệ:**
  - Bắt buộc $\text{Duration} \ge 60$ giây ($> 0.0167$ giờ).
  - Bắt buộc $\text{trip\_distance} > 0.1$ dặm.
  - Vận tốc hợp lý: $1 \text{ mph} \le \text{Speed} \le 80 \text{ mph}$. (Vận tốc $> 100$ mph trong khu vực nội đô NYC được coi là lỗi định vị/ghi nhận).

---

### M10. Doanh thu trung bình trên mỗi chuyến (Revenue per Trip)
- **Tên hiển thị:** `Revenue per Trip` / `Doanh thu / chuyến`
- **Ý nghĩa nghiệp vụ:** Số tiền bình quân thu được trên một chuyến xe, phản ánh giá trị đơn hàng trung bình.
- **Công thức:**
  $$\text{Revenue per Trip} = \frac{\sum \text{total\_amount}}{\text{Trip Count}}$$
- **Đơn vị đo:** USD/chuyến ($/trip)
- **Tính chất tổng hợp:** Phi cộng dồn (Non-Additive).

---

### M11. Tuyến đường phổ biến (Popular Route)
- **Tên hiển thị:** `Popular Route` / `Top N Tuyến đường`
- **Ý nghĩa nghiệp vụ:** Cặp điểm đón và điểm trả có lưu lượng chuyến xe qua lại cao nhất.
- **Định nghĩa:** Cặp có thứ tự: $(\text{Pickup LocationID}, \text{Drop-off LocationID})$. Tuyến $A \rightarrow B$ được tính độc lập với tuyến $B \rightarrow A$.
- **Chỉ số xếp hạng:**
  $$\text{Rank} = \text{RANK() OVER (ORDER BY COUNT(TripID) DESC)}$$
- **Xử lý hòa điểm (Ties):** Sử dụng `DENSE_RANK()` hoặc sắp xếp phụ theo tổng doanh thu (`total_amount`).

---

### M12. Các chỉ số so sánh cùng kỳ (Period-over-Period Metrics)
- **Tên hiển thị:** `MoM Growth %`, `YoY Growth %`
- **Công thức:**
  $$\text{MoM Growth \%} = \frac{\text{Metric}_{\text{Tháng hiện tại}} - \text{Metric}_{\text{Tháng liền trước}}}{\text{Metric}_{\text{Tháng liền trước}}} \times 100\%$$
  $$\text{YoY Growth \%} = \frac{\text{Metric}_{\text{Năm 2023, Tháng M}} - \text{Metric}_{\text{Năm 2022, Tháng M}}}{\text{Metric}_{\text{Năm 2022, Tháng M}}} \times 100\%$$
- **Đơn vị đo:** Tỷ lệ phần trăm (%)
- **Lưu ý:** Cần đồng nhất số ngày so sánh nếu là kỳ dở dang. Vì dữ liệu chọn là trọn vẹn 24 tháng (2022–2023), phép tính so sánh tháng đầy đủ là hoàn toàn hợp lệ.
