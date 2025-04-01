# Hướng dẫn ETL Rhythmic

Tài liệu này mô tả chi tiết quy trình ETL (Extract, Transform, Load) trong dự án Rhythmic-ETL, từ việc thu thập dữ liệu đến xử lý và lưu trữ.

## Tổng quan kiến trúc

Hệ thống ETL của Rhythmic bao gồm các thành phần chính:

1. **Kafka**: Nhận dữ liệu streaming từ Eventsim và các nguồn khác
2. **Flink**: Xử lý dữ liệu streaming theo thời gian thực
3. **GCS (Google Cloud Storage)**: Lưu trữ dữ liệu đã xử lý
4. **Airflow**: Điều phối các tác vụ xử lý dữ liệu theo lịch trình

## Cài đặt hệ thống

### Chuẩn bị môi trường

Dự án chạy trên 3 máy ảo riêng biệt trên GCP:

1. **kafka-vm**: Chứa Kafka và Eventsim
2. **flink-vm**: Chứa Flink để xử lý dữ liệu streaming
3. **airflow-vm**: Chứa Airflow để điều phối các tác vụ

### Setup VMs

Trên mỗi VM, cần thực hiện các bước cài đặt cơ bản:

```bash
# Cài đặt Git, Docker và các công cụ cần thiết
sudo apt-get update
sudo apt-get install -y git docker.io docker-compose jq netcat
sudo usermod -aG docker $USER

# Khởi động lại shell hoặc logout/login để áp dụng quyền Docker
newgrp docker

# Clone repository
git clone <repository_url>
cd Rhythmic-ETL
```

### 1. Setup kafka-vm

```bash
# Di chuyển đến thư mục kafka
cd kafka

# Cấp quyền thực thi
chmod +x prepare_data.sh

# Chuẩn bị dữ liệu (tải Million Song Dataset)
./prepare_data.sh

# Khởi động các dịch vụ
docker-compose up -d
```

Sau khi chạy, kiểm tra trạng thái:

```bash
# Xem các container
docker-compose ps

# Kiểm tra logs
docker-compose logs
```

### 2. Setup flink-vm

Trước khi chạy, cần chuẩn bị credentials GCP:

```bash
# Di chuyển đến thư mục flink
cd flink

# Tạo thư mục secrets
mkdir -p secrets

# Copy GCP credentials
# Lưu ý: credentials cần có quyền Storage Admin
cp /path/to/credentials.json secrets/cred.json

# Cấp quyền thực thi
chmod +x *.sh

# Kiểm tra cài đặt
./check_setup.sh

# Khởi động các dịch vụ
docker-compose up -d

# Chạy Flink jobs
./run_jobs.sh
```

### 3. Setup airflow-vm

```bash
# Di chuyển đến thư mục airflow
cd airflow

# Tạo thư mục cần thiết
mkdir -p dags logs plugins config secrets

# Copy GCP credentials
cp /path/to/credentials.json secrets/cred.json

# Thiết lập quyền
chmod -R 777 logs plugins

# Khởi tạo Airflow
docker-compose up airflow-init

# Khởi động dịch vụ
docker-compose up -d
```

Truy cập Airflow UI tại: http://airflow-vm:8080 (username: airflow, password: airflow)

## Luồng dữ liệu

### 1. Nguồn dữ liệu

Dữ liệu được tạo ra bởi **Eventsim** - một công cụ mô phỏng sự kiện giống như dữ liệu từ ứng dụng nghe nhạc. Eventsim sử dụng Million Song Dataset làm nguồn dữ liệu về bài hát.

Các loại sự kiện bao gồm:
- **listen_events**: Sự kiện nghe nhạc
- **page_view_events**: Sự kiện xem trang
- **auth_events**: Sự kiện xác thực

### 2. Kafka Streaming

Sự kiện từ Eventsim được đưa vào Kafka theo các topics tương ứng:
- `listen_events`
- `page_view_events`
- `auth_events`

### 3. Flink Processing

Flink đọc dữ liệu từ Kafka, xử lý và chuẩn hóa, sau đó lưu vào GCS với các partition phù hợp:

```
gs://rhythmic-bucket/listen_events/year=2023/month=04/day=01/hour=23/
```

### 4. Airflow Orchestration

Airflow quản lý các tác vụ xử lý dữ liệu theo lịch trình, bao gồm:
- **Kiểm tra dữ liệu**: Đảm bảo dữ liệu mới đã có trong GCS
- **Xử lý batch**: Thực hiện các phân tích batch trên dữ liệu
- **Tạo báo cáo**: Tạo các báo cáo phân tích

## Kiểm tra và xử lý sự cố

### Kiểm tra Kafka

```bash
# SSH vào kafka-vm
ssh kafka-vm

# Liệt kê topics
docker-compose exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092

# Xem dữ liệu trong topic
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic listen_events --from-beginning --max-messages 5
```

### Kiểm tra Flink

```bash
# SSH vào flink-vm
ssh flink-vm

# Xem trạng thái jobs
docker-compose exec jobmanager flink list

# Xem logs
docker-compose logs jobmanager
```

### Kiểm tra Airflow

```bash
# SSH vào airflow-vm
ssh airflow-vm

# Xem logs
docker-compose logs webserver

# Xem logs của DAG cụ thể
docker-compose exec webserver airflow dags list
docker-compose exec webserver airflow tasks list <dag_id>
docker-compose exec webserver airflow dags test <dag_id> <execution_date>
```

## Xử lý lỗi thường gặp

### 1. Kafka không nhận được dữ liệu từ Eventsim

**Kiểm tra**:
```bash
# Kiểm tra Eventsim có đang chạy
docker-compose ps eventsim

# Kiểm tra logs
docker-compose logs eventsim
```

**Giải pháp**:
- Đảm bảo container eventsim đang hoạt động
- Kiểm tra config.json của Eventsim
- Khởi động lại: `docker-compose restart eventsim`

### 2. Flink không kết nối được với Kafka

**Kiểm tra**:
```bash
# Kiểm tra kết nối
nc -z -v kafka-vm 9092

# Kiểm tra logs
docker-compose logs jobmanager
```

**Giải pháp**:
- Đảm bảo kafka-vm đang chạy và có thể truy cập được
- Kiểm tra cấu hình mạng
- Chỉnh sửa biến môi trường: `KAFKA_BROKER=kafka-vm:9092`

### 3. Flink không lưu được dữ liệu vào GCS

**Kiểm tra**:
```bash
# Kiểm tra credentials
ls -la secrets/cred.json
```

**Giải pháp**:
- Đảm bảo file credentials tồn tại và có định dạng đúng
- Kiểm tra quyền của service account trong GCP
- Thiết lập biến môi trường: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json`

### 4. Airflow DAGs không chạy

**Kiểm tra**:
```bash
# Kiểm tra trạng thái DAGs
docker-compose exec webserver airflow dags list-runs
```

**Giải pháp**:
- Kiểm tra cú pháp của DAGs
- Đảm bảo các connections đã được cấu hình đúng
- Khởi động lại webserver: `docker-compose restart webserver`
