# Hướng dẫn triển khai dự án Streamify

## Giới thiệu
Streamify là dự án xử lý dữ liệu thời gian thực mô phỏng dịch vụ phát nhạc trực tuyến. Dự án sử dụng nhiều công nghệ như Kafka, Spark Streaming, dbt, Docker, Airflow, Terraform và GCP.

## Yêu cầu tiên quyết
- Google Cloud Platform account
- Docker và Docker Compose
- Terraform
- Python 3.8+
- Java 8+

## Các bước triển khai

### Bước 1: Cài đặt môi trường
1. Clone repository về máy local
2. Cài đặt các công cụ cần thiết:
   - Docker & Docker Compose
   - Terraform
   - Python & pip
   - Google Cloud SDK

### Bước 2: Thiết lập GCP
1. Tạo project mới trên GCP
2. Bật các API cần thiết:
   - Compute Engine API
   - Storage API
   - BigQuery API
3. Tạo service account với quyền:
   - Compute Admin
   - Storage Admin
   - BigQuery Admin
4. Tải service account key (JSON) và lưu vào thư mục an toàn

### Bước 3: Triển khai hạ tầng bằng Terraform
1. Di chuyển vào thư mục terraform:
   ```bash
   cd terraform
   ```
2. Khởi tạo Terraform:
   ```bash
   terraform init
   ```
3. Xem trước các thay đổi:
   ```bash
   terraform plan -var="project_id=YOUR_PROJECT_ID"
   ```
4. Triển khai hạ tầng:
   ```bash
   terraform apply -var="project_id=YOUR_PROJECT_ID"
   ```

### Bước 4: Kết nối SSH vào các VM
1. Tạo cặp khóa SSH (nếu chưa có)
2. Cấu hình SSH trong file ~/.ssh/config:
   ```
   Host kafka-vm
     HostName [IP_ADDRESS]
     User [USERNAME]
     IdentityFile ~/.ssh/id_rsa
   
   Host spark-vm
     HostName [IP_ADDRESS]
     User [USERNAME]
     IdentityFile ~/.ssh/id_rsa
   
   Host airflow-vm
     HostName [IP_ADDRESS]
     User [USERNAME]
     IdentityFile ~/.ssh/id_rsa
   ```

### Bước 5: Thiết lập Kafka và Eventsim
1. SSH vào Kafka VM:
   ```bash
   ssh kafka-vm
   ```
2. Clone repository:
   ```bash
   git clone [REPO_URL]
   cd streamify
   ```
3. Chạy Kafka và Zookeeper bằng Docker Compose:
   ```bash
   cd kafka
   docker-compose up -d
   ```
4. Kiểm tra Kafka đã hoạt động:
   ```bash
   docker-compose ps
   ```
5. Chạy Eventsim để tạo dữ liệu mẫu:
   ```bash
   cd ../eventsim
   docker-compose up -d
   ```

### Bước 6: Thiết lập Spark Streaming
1. SSH vào Spark VM:
   ```bash
   ssh spark-vm
   ```
2. Clone repository:
   ```bash
   git clone [REPO_URL]
   cd streamify
   ```
3. Cài đặt dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Cài đặt Spark:
   ```bash
   cd setup
   ./install_spark.sh
   ```
5. Cấu hình biến môi trường cho Spark:
   ```bash
   export KAFKA_ADDRESS=[KAFKA_VM_IP]
   export GCP_GCS_BUCKET=[YOUR_BUCKET_NAME]
   ```
6. Chạy ứng dụng Spark Streaming:
   ```bash
   cd ../spark_streaming
   spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.2 stream_all_events.py
   ```

### Bước 7: Thiết lập Airflow
1. SSH vào Airflow VM:
   ```bash
   ssh airflow-vm
   ```
2. Clone repository:
   ```bash
   git clone [REPO_URL]
   cd streamify
   ```
3. Cài đặt Airflow bằng Docker Compose:
   ```bash
   cd airflow
   mkdir -p ./logs ./plugins
   echo "AIRFLOW_UID=$(id -u)" > .env
   docker-compose up -d
   ```
4. Kiểm tra Airflow đã hoạt động:
   ```bash
   docker-compose ps
   ```
5. Truy cập Airflow UI tại: http://[AIRFLOW_VM_IP]:8080 (username: airflow, password: airflow)

### Bước 8: Thiết lập dbt
1. Cài đặt dbt:
   ```bash
   pip install dbt-core dbt-bigquery
   ```
2. Cấu hình dbt:
   ```bash
   cd dbt
   dbt init
   ```
3. Chỉnh sửa file profiles.yml để kết nối với BigQuery
4. Chạy dbt models:
   ```bash
   dbt run
   ```

### Bước 9: Xác minh luồng dữ liệu
1. Kiểm tra dữ liệu đã được lưu vào GCS Bucket
2. Xác minh bảng đã được tạo trong BigQuery
3. Tạo dashboard để theo dõi dữ liệu

## Xử lý sự cố

### Kafka không hoạt động
- Kiểm tra logs: `docker-compose logs`
- Đảm bảo cổng 9092 đã được mở
- Khởi động lại: `docker-compose restart`

### Spark Streaming lỗi
- Kiểm tra biến môi trường đã được đặt chính xác
- Xem logs tại: `spark-submit --verbose ...`
- Đảm bảo kết nối giữa Spark và Kafka

### Airflow DAGs không chạy
- Kiểm tra logs: `docker-compose logs airflow-webserver`
- Đảm bảo connections và variables đã được cấu hình đúng

## Kết luận
Sau khi hoàn thành các bước trên, bạn sẽ có một pipeline dữ liệu hoàn chỉnh xử lý dữ liệu thời gian thực từ Kafka, qua Spark Streaming, lưu trữ trên GCS, xử lý bằng Airflow và dbt, và cuối cùng là phân tích trên BigQuery.
