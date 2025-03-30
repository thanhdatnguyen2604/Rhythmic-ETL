# Cấu trúc dự án Rhythmic-ETL

Dự án Rhythmic-ETL là một pipeline xử lý dữ liệu thời gian thực cho dịch vụ phát nhạc trực tuyến. Dưới đây là cấu trúc thư mục và mục đích của từng thành phần.

## 1. Terraform - Hạ tầng GCP

```
terraform/
├── main.tf          # Định nghĩa tài nguyên trên GCP (VM, bucket, dataset)
├── variables.tf     # Khai báo biến cho Terraform
└── outputs.tf       # Định nghĩa đầu ra (IP, tên resource)
```

**Mục đích**: Triển khai hạ tầng trên GCP, bao gồm:
- 3 máy ảo e2-micro (tối ưu chi phí) cho Kafka, Flink và Airflow
- GCS bucket để lưu trữ dữ liệu
- BigQuery dataset để phân tích dữ liệu

## 2. Kafka - Streaming Platform

```
kafka/
├── config/
│   └── server.properties    # Cấu hình tối ưu cho Kafka
├── docker-compose.yml       # Triển khai Kafka và Zookeeper
└── data/                    # Thư mục lưu dữ liệu (được tạo khi chạy)
```

**Mục đích**: Cung cấp nền tảng xử lý stream để:
- Nhận và lưu trữ các sự kiện nghe nhạc
- Phân phối dữ liệu đến ứng dụng Flink
- Cấu hình tối ưu cho môi trường e2-micro

## 3. Flink - Streaming Processing

```
flink/
├── config/
│   └── flink-conf.yaml      # Cấu hình tối ưu cho Flink
├── docker-compose.yml       # Triển khai Flink JobManager và TaskManager
└── data/                    # Thư mục lưu dữ liệu (được tạo khi chạy)

flink_jobs/
├── stream_all_events.py     # Job xử lý các sự kiện từ Kafka
├── streaming_functions.py   # Các hàm xử lý và biến đổi dữ liệu
└── schema.py                # Định nghĩa schema cho các loại sự kiện
```

**Mục đích**: Xử lý dữ liệu streaming từ Kafka để:
- Biến đổi dữ liệu thành format phù hợp
- Lưu trữ kết quả vào GCS theo định dạng parquet
- Phân vùng dữ liệu theo ngày, giờ để tối ưu truy vấn

## 4. Airflow - Orchestration

```
airflow/
├── config/
│   └── airflow.cfg          # Cấu hình tối ưu cho Airflow
├── docker-compose.yml       # Triển khai Airflow với LocalExecutor
├── dags/                    # Thư mục chứa DAGs
│   ├── gcs_to_bigquery.py   # DAG tạo external tables từ GCS
│   └── trigger_dbt.py       # DAG kích hoạt transformation dbt
└── logs/                    # Thư mục lưu logs (được tạo khi chạy)
```

**Mục đích**: Lập lịch và điều phối các công việc để:
- Tạo external tables từ dữ liệu trên GCS
- Kích hoạt các transformation dbt
- Giám sát và quản lý luồng dữ liệu

## 5. dbt - Transformation

```
dbt/
├── dbt_project.yml          # Cấu hình dbt project
├── profiles.yml             # Cấu hình kết nối đến BigQuery
├── models/                  # Chứa các model SQL
│   ├── staging/             # Staging models
│   │   ├── stg_listen_events.sql
│   │   ├── stg_page_view_events.sql
│   │   └── stg_auth_events.sql
│   ├── marts/               # Dimensional models
│   │   ├── dim_users.sql
│   │   ├── dim_songs.sql
│   │   └── fact_listens.sql
│   └── schema.yml           # Định nghĩa schema và tests
└── macros/                  # Macros SQL tái sử dụng
```

**Mục đích**: Biến đổi dữ liệu trong BigQuery để:
- Tạo các bảng dimension và fact theo mô hình dimensional
- Tạo các bảng tổng hợp để phân tích
- Áp dụng các kiểm tra chất lượng dữ liệu

## 6. Scripts - Công cụ hỗ trợ

```
scripts/
├── budget_alert.sh          # Thiết lập cảnh báo ngân sách GCP
└── vm_control.sh            # Điều khiển bật/tắt VM để tiết kiệm chi phí
```

**Mục đích**: Cung cấp các công cụ để:
- Quản lý chi phí GCP
- Bật/tắt VM khi cần thiết
- Tự động hóa các tác vụ quản trị

## 7. Docs - Tài liệu

```
docs/
├── README.md                # Tổng quan về tối ưu chi phí
├── kafka_optimization.md    # Tài liệu về tối ưu Kafka
├── flink_optimization.md    # Tài liệu về tối ưu Flink
├── airflow_optimization.md  # Tài liệu về tối ưu Airflow
├── gcp_optimization.md      # Tài liệu về tối ưu GCP
├── structure-project.md     # Cấu trúc dự án (file này)
└── ETL.md                   # Luồng ETL và cách triển khai
```

**Mục đích**: Cung cấp tài liệu về:
- Cấu trúc và thành phần của dự án
- Cách tối ưu chi phí
- Hướng dẫn triển khai và vận hành

## 8. Eventsim - Data Generator

```
eventsim/
└── docker-compose.yml       # Triển khai công cụ mô phỏng sự kiện
```

**Mục đích**: Tạo dữ liệu mẫu để mô phỏng:
- Các sự kiện nghe nhạc từ người dùng
- Các page view trên ứng dụng
- Các sự kiện xác thực
