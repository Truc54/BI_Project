# Kế hoạch Tổng quan Phase 2: Triển khai ETL & Kho dữ liệu

## 1. Mục tiêu
Triển khai hệ thống Data Warehouse hoàn chỉnh cho tập dữ liệu NYC Yellow Taxi 2022–2023 (24 tháng) theo kiến trúc 3 tầng: **Source > Staging > clean_view > DDS**.

* **Nền tảng công nghệ:** PostgreSQL 17, Mage AI (điều phối ingestion), dbt Core (chuyển đổi & kiểm thử), Docker Compose.
* **Tài liệu tham chiếu chính:**
  * Hướng dẫn thực hành: `01_Hướng dẫn cài đặt và sử dụng Mage.AI.pdf` & `02_Hướng dẫn nạp dữ liệu tăng dần vào stage.pdf`.
  * Tài liệu thiết kế Phase 1: Báo cáo `report.pdf` và các tài liệu trong `deliverables/phase1/`.

---

## 2. Kiến trúc Luồng dữ liệu

```text
24 tệp Parquet (dataset/)
        │
        ▼ (Trực)
Mage AI Ingestion (Incremental Watermark) ──► PostgreSQL: Schema [control] (Watermark & Log)
        │
        ▼ (Trực)
PostgreSQL: Schema [stage] (raw_yellow_tripdata, raw_taxi_zones)
        │
        ▼ (Lộc)
dbt Staging / clean_view (stg_yellow_trips_cleaned: làm sạch, gán cờ, phân nhóm)
        │
        ▼ (Dũng)
dbt Marts / DDS (8 Bảng Dimension + FactYellowTaxiTrip)
        │
        ▲ (Phúc)
dbt Tests & QA (Đối soát số dòng, kiểm tra toàn vẹn, 13 query C1-C8 & E1-E5)
```

---

## 3. Phân công Công việc

| Thành viên | Trách nhiệm chính | Chi tiết kế hoạch |
| :--- | :--- | :--- |
| **Trần Lê Trung Trực** | **Nạp từ Source vào Staging:** Dựng môi trường Docker (Postgres 17, Mage), tạo schema `control` & `stage`, xây dựng pipeline Mage nạp tăng dần 24 tệp Parquet theo cơ chế Watermark. | [phase2_truc.md](phase2_truc.md) |
| **Lê Văn Lộc** | **Staging sang clean_view:** Xây dựng dbt staging models, chuẩn hóa ngày giờ, xử lý dị thường, cờ `is_in_study_period`, phân nhóm khách & cự ly, map mã Unknown. | [phase2_loc.md](phase2_loc.md) |
| **Dương Viết Dũng** | **clean_view sang DW (DDS):** Dựng 8 bảng Dimension, xây dựng bảng Fact nạp incremental, ánh xạ Surrogate Keys, tối ưu hóa Index trên PostgreSQL. | [phase2_dung.md](phase2_dung.md) |
| **Nguyễn Hồng Phúc** | **Kiểm tra, chạy thử & QA:** Viết bộ test dbt (khóa chính, khóa ngoại, đối soát số dòng), viết 13 câu SQL chạy thử C1–C8 & E1–E5, kịch bản xử lý khi có lỗi pipeline. | [phase2_phuc.md](phase2_phuc.md) |

---

## 4. Lộ trình Triển khai (Timeline 2 tuần)

* **Giai đoạn 1 (Tuần 1):**
  * Trực hoàn thành dựng Docker, CSDL và pipeline nạp Source ➔ Staging.
  * Lộc hoàn thành tầng `clean_view` trên dbt.
  * Dũng khởi tạo các bảng Dimension tĩnh.
* **Giai đoạn 2 (Tuần 2):**
  * Dũng hoàn thành nạp bảng Fact và tối ưu Index trên DDS.
  * Phúc chạy toàn bộ test kiểm tra chất lượng dữ liệu và thực thi 13 query nghiệm thu.
  * Nhóm sửa các lỗi phát sinh, hoàn thiện báo cáo Phase 2 (`7_BaoCao.pdf`) và đóng gói mã nguồn (`7_Src.zip`).
