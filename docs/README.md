# Tối ưu hóa Rhythmic-ETL cho Chi phí Thấp

Tài liệu này mô tả các chiến lược tối ưu hóa cho dự án Rhythmic-ETL để chạy trên môi trường hạn chế tài nguyên của Google Cloud Platform, đặc biệt là tận dụng gói Free Tier và tín dụng $300.

## Tổng quan

Dự án Rhythmic-ETL là một pipeline xử lý dữ liệu thời gian thực mô phỏng dịch vụ phát nhạc trực tuyến. Các công nghệ chính bao gồm:

1. **Kafka** - Nền tảng stream processing
2. **Flink** - Framework xử lý streaming
3. **Airflow** - Công cụ lập lịch và điều phối 
4. **GCP** - Hạ tầng đám mây (Compute Engine, GCS, BigQuery)

Với cách tiếp cận ban đầu, chi phí ước tính có thể lên tới $200-300 mỗi tháng, vượt quá ngân sách dành cho dự án demo. Các tối ưu hóa trong tài liệu này giúp giảm chi phí xuống còn khoảng $30-50 mỗi tháng hoặc thậm chí thấp hơn với việc tắt VM khi không sử dụng.

## Danh sách các tối ưu hóa

### 1. [Tối ưu Kafka](kafka_optimization.md)
- Giảm số lượng partition xuống 1 cho mỗi topic
- Giảm kích thước segment file (log.segment.bytes=100MB)
- Giảm retention period (log.retention.hours=24)
- Giảm bộ nhớ cho Java heap (KAFKA_HEAP_OPTS="-Xmx512M -Xms256M")

### 2. [Tối ưu Flink](flink_optimization.md)
- Chạy ở chế độ standalone thay vì cluster
- Giảm số lượng task slot xuống 1
- Giảm JVM heap size (taskmanager.memory.process.size: 500mb)
- Giảm bộ nhớ cho network buffer (taskmanager.memory.network.fraction: 0.1)

### 3. [Tối ưu Airflow](airflow_optimization.md)
- Sử dụng LocalExecutor thay vì CeleryExecutor
- Giảm số lượng worker
- Tăng khoảng thời gian giữa các lần chạy DAG
- Giảm logging level

### 4. [Tối ưu GCP](gcp_optimization.md)
- Thiết lập giới hạn chi tiêu hàng ngày/hàng tuần
- Sử dụng regional bucket thay vì multi-regional
- Tắt VM khi không sử dụng
- Sử dụng preemptible VMs

## Cách triển khai

### Cấu hình hạ tầng

Các tệp Terraform trong thư mục `terraform/` đã được tối ưu để sử dụng VM e2-micro thay vì e2-standard-4 và các cấu hình phù hợp cho môi trường chi phí thấp.

### Cấu hình các dịch vụ

Mỗi dịch vụ (Kafka, Flink, Airflow) có thư mục cấu hình riêng với các file `docker-compose.yml` và cấu hình tương ứng:
- `kafka/docker-compose.yml` và `kafka/config/server.properties`
- `flink/docker-compose.yml` và `flink/config/flink-conf.yaml`
- `airflow/docker-compose.yml` và `airflow/config/airflow.cfg`

### Quản lý chi phí

Các script trong thư mục `scripts/` hỗ trợ quản lý chi phí và VM:
- `scripts/budget_alert.sh` - Thiết lập cảnh báo ngân sách
- `scripts/vm_control.sh` - Điều khiển bật/tắt VM

## Hướng dẫn sử dụng

### Khởi động và dừng các dịch vụ

1. **Bật VM để sử dụng**:
   ```bash
   ./scripts/vm_control.sh [PROJECT_ID] [ZONE] start
   ```

2. **Khởi động dịch vụ Kafka**:
   ```bash
   cd kafka
   docker-compose up -d
   ```

3. **Khởi động dịch vụ Flink**:
   ```bash
   cd flink
   docker-compose up -d
   ```

4. **Khởi động dịch vụ Airflow**:
   ```bash
   cd airflow
   docker-compose up -d
   ```

5. **Dừng VM sau khi sử dụng**:
   ```bash
   ./scripts/vm_control.sh [PROJECT_ID] [ZONE] stop
   ```

### Thiết lập cảnh báo ngân sách

```bash
./scripts/budget_alert.sh [PROJECT_ID] [BUDGET_AMOUNT] [EMAIL]
```

## Điều chỉnh đối với dữ liệu Million Song Dataset

Dự án đã được điều chỉnh để sử dụng Million Song Dataset Subset (10,000 bài hát, 1.8GB) thay vì toàn bộ dataset (300GB). Điều này giúp giảm tải trọng xử lý và lưu trữ, phù hợp với môi trường hạn chế tài nguyên.

## Tài liệu liên quan

- [Hướng dẫn triển khai đầy đủ](../contructions.md)
- [Cấu trúc dự án](../structure-project.md)

## Tác giả

Dự án Rhythmic-ETL và các tối ưu hóa này được phát triển như một phần của khóa học Data Engineer Zoomcamp. 