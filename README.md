# Rhythmic-ETL: Streaming và Batch Data Processing

Rhythmic-ETL là một dự án End-to-End Data Engineering sử dụng Kafka, Flink, và Airflow để xử lý dữ liệu streaming và batch từ ứng dụng phát nhạc.

## Kiến trúc hệ thống

Dự án triển khai trên 3 VM riêng biệt trên GCP:

1. **kafka-vm**: Chứa Kafka Cluster và ứng dụng Eventsim để mô phỏng dữ liệu streaming.
2. **flink-vm**: Chứa Flink để xử lý dữ liệu streaming và lưu vào GCS.
3. **airflow-vm**: Chứa Airflow để điều phối các tác vụ ETL và Analytics.

![Kiến trúc hệ thống](docs/images/architecture.png)

## Thành phần chính

- **Terraform**: Tự động hóa việc triển khai hạ tầng trên GCP
- **Kafka & Eventsim**: Tạo và xử lý các sự kiện dạng streaming
- **Flink**: Xử lý dữ liệu streaming theo thời gian thực
- **GCS**: Lưu trữ dữ liệu phân tích
- **Airflow**: Điều phối các quá trình ETL

## Quick Start

1. **Setup Terraform**:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

2. **Setup Kafka**:
   ```bash
   # SSH vào kafka-vm
   cd kafka
   chmod +x prepare_data.sh
   ./prepare_data.sh
   docker-compose up -d
   ```

3. **Setup Flink**:
   ```bash
   # SSH vào flink-vm
   cd flink
   mkdir -p secrets
   # Copy GCP credentials vào secrets/cred.json
   chmod +x *.sh
   ./check_setup.sh
   docker-compose up -d
   ./run_jobs.sh
   ```

4. **Setup Airflow**:
   ```bash
   # SSH vào airflow-vm
   cd airflow
   mkdir -p dags logs plugins config secrets
   # Copy GCP credentials vào secrets/cred.json
   docker-compose up airflow-init
   docker-compose up -d
   ```

## Tài liệu chi tiết

- [Hướng dẫn ETL](docs/ETL.md)
- [Kafka & Eventsim](kafka/README.md)
- [Flink Jobs](flink/README.md)
- [Airflow](airflow/README.md)
- [Million Song Dataset](docs/million_song_dataset.md)
- [GCP Optimization](docs/gcp_optimization.md)

## Ví dụ phân tích

1. **Top 10 bài hát được nghe nhiều nhất**:
   ```sql
   SELECT song, artist, COUNT(*) as plays
   FROM listen_events
   GROUP BY song, artist
   ORDER BY plays DESC
   LIMIT 10
   ```

2. **Mức độ tương tác theo giờ trong ngày**:
   ```sql
   SELECT EXTRACT(HOUR FROM datetime) as hour, COUNT(*) as interactions
   FROM page_view_events
   GROUP BY hour
   ORDER BY hour
   ```

## Đóng góp

Hãy đọc [CONTRIBUTING.md](CONTRIBUTING.md) để biết thêm thông tin về cách đóng góp vào dự án.

## Giấy phép

Dự án này được phân phối dưới Giấy phép MIT. Xem [LICENSE](LICENSE) để biết thêm chi tiết.