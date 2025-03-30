# Luồng ETL và Hướng dẫn triển khai Rhythmic-ETL

## Tổng quan luồng ETL

Luồng ETL (Extract-Transform-Load) của dự án Rhythmic-ETL xử lý dữ liệu streaming từ nguồn đến đích với mô hình lambda architecture (kết hợp xử lý batch và streaming).

![Luồng ETL](https://i.imgur.com/XYZabc.png)

### Các bước chính trong luồng ETL:

1. **Extract (Trích xuất)**: 
   - Eventsim tạo dữ liệu mô phỏng các sự kiện nghe nhạc
   - Dữ liệu được đưa vào Kafka dưới dạng JSON
   - Ba loại sự kiện chính: listen_events, page_view_events, auth_events

2. **Transform (Biến đổi)**:
   - **Stream Processing**: Flink đọc dữ liệu từ Kafka, biến đổi và lưu vào GCS
   - **Batch Processing**: dbt thực hiện các biến đổi trên BigQuery
   - **Data Modeling**: Xây dựng mô hình dimensional (star schema) với dim và fact tables

3. **Load (Tải)**:
   - Dữ liệu sau khi xử lý được lưu vào GCS dưới dạng parquet
   - Airflow tạo external tables trong BigQuery từ dữ liệu GCS
   - dbt transforms tạo ra các bảng phân tích cuối cùng trong BigQuery

## Hướng dẫn triển khai từng bước

Dưới đây là các bước để triển khai toàn bộ dự án Rhythmic-ETL, tận dụng tối đa tín dụng miễn phí $300 của GCP.

### Bước 1: Thiết lập GCP Project

1. Tạo GCP project mới:
   - Truy cập [Google Cloud Console](https://console.cloud.google.com/)
   - Tạo project mới (VD: rhythmic-etl-project)
   - Bật tính năng thanh toán và liên kết với tín dụng $300

2. Bật các API cần thiết:
   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable storage.googleapis.com
   gcloud services enable bigquery.googleapis.com
   ```

3. Tạo Service Account:
   - Vào IAM & Admin > Service Accounts
   - Tạo service account với quyền:
     - Compute Admin
     - Storage Admin
     - BigQuery Admin
   - Tải xuống key JSON và lưu tại vị trí an toàn

### Bước 2: Chuẩn bị môi trường phát triển

1. Cài đặt công cụ cần thiết:
   ```bash
   # Google Cloud SDK
   curl https://sdk.cloud.google.com | bash
   gcloud init

   # Terraform
   # Cài đặt theo hướng dẫn tại: https://learn.hashicorp.com/tutorials/terraform/install-cli

   # Các công cụ khác
   pip install apache-airflow dbt-bigquery
   ```

2. Clone repository:
   ```bash
   git clone https://github.com/your-username/Rhythmic-ETL.git
   cd Rhythmic-ETL
   ```

3. Thiết lập biến môi trường:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/your/service-account-key.json"
   export TF_VAR_project_id="rhythmic-etl-project"
   ```

### Bước 3: Triển khai hạ tầng với Terraform

1. Khởi tạo Terraform:
   ```bash
   cd terraform
   terraform init
   ```

2. Tạo file terraform.tfvars với nội dung:
   ```
   project_id          = "rhythmic-etl-project"
   region              = "us-central1"
   zone                = "us-central1-a"
   gcs_bucket_name     = "rhythmic-bucket"
   bq_dataset_name     = "rhythmic_dataset"
   ssh_username        = "your-username"
   ssh_public_key_path = "~/.ssh/id_rsa.pub"
   ```

3. Triển khai hạ tầng:
   ```bash
   terraform plan
   terraform apply
   ```

4. Ghi lại thông tin đầu ra (IP, tên bucket):
   ```bash
   terraform output
   ```

### Bước 4: Thiết lập SSH và kết nối VMs

1. Tạo SSH key nếu chưa có:
   ```bash
   ssh-keygen -t rsa -b 4096
   ```

2. Cấu hình SSH trong file `~/.ssh/config`:
   ```
   Host kafka-vm
     HostName [KAFKA_VM_IP]
     User [SSH_USERNAME]
     IdentityFile ~/.ssh/id_rsa

   Host flink-vm
     HostName [FLINK_VM_IP]
     User [SSH_USERNAME]
     IdentityFile ~/.ssh/id_rsa

   Host airflow-vm
     HostName [AIRFLOW_VM_IP]
     User [SSH_USERNAME]
     IdentityFile ~/.ssh/id_rsa
   ```

3. Kiểm tra kết nối:
   ```bash
   ssh kafka-vm
   ssh flink-vm
   ssh airflow-vm
   ```

### Bước 5: Thiết lập Kafka và Eventsim

1. SSH vào Kafka VM:
   ```bash
   ssh kafka-vm
   ```

2. Cài đặt Docker và Git:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose git
   sudo usermod -aG docker $USER
   # Đăng xuất và đăng nhập lại
   ```

3. Clone repository:
   ```bash
   git clone https://github.com/your-username/Rhythmic-ETL.git
   cd Rhythmic-ETL
   ```

4. Thiết lập và khởi động Kafka:
   ```bash
   cd kafka
   mkdir -p data config
   
   # Tạo file config/server.properties từ tài liệu
   vi config/server.properties
   # Sao chép nội dung từ docs/kafka_optimization.md

   # Khởi động Kafka
   docker-compose up -d
   ```

5. Cài đặt và khởi động Eventsim:
   ```bash
   cd ../eventsim
   # Cấu hình Eventsim để sử dụng Million Song Dataset Subset
   vi docker-compose.yml
   
   # Khởi động Eventsim
   docker-compose up -d
   ```

### Bước 6: Thiết lập Flink và Jobs

1. SSH vào Flink VM:
   ```bash
   ssh flink-vm
   ```

2. Cài đặt Docker và Git:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose git
   sudo usermod -aG docker $USER
   # Đăng xuất và đăng nhập lại
   ```

3. Clone repository:
   ```bash
   git clone https://github.com/your-username/Rhythmic-ETL.git
   cd Rhythmic-ETL
   ```

4. Thiết lập và khởi động Flink:
   ```bash
   cd flink
   mkdir -p data config
   
   # Tạo file config/flink-conf.yaml từ tài liệu
   vi config/flink-conf.yaml
   # Sao chép nội dung từ docs/flink_optimization.md

   # Khởi động Flink
   docker-compose up -d
   ```

5. Chuẩn bị và chạy Flink Jobs:
   ```bash
   # Cài đặt Python và dependencies
   sudo apt-get install -y python3-pip
   pip3 install pyflink kafka-python google-cloud-storage

   # Thiết lập biến môi trường
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
   export KAFKA_BROKER="kafka-vm:9092"
   export GCS_BUCKET="rhythmic-bucket"

   # Chuyển đổi mã nguồn từ Spark sang Flink
   cd ../flink_jobs
   
   # Chạy Flink job
   flink run -py stream_all_events.py
   ```

### Bước 7: Thiết lập Airflow

1. SSH vào Airflow VM:
   ```bash
   ssh airflow-vm
   ```

2. Cài đặt Docker và Git:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose git
   sudo usermod -aG docker $USER
   # Đăng xuất và đăng nhập lại
   ```

3. Clone repository:
   ```bash
   git clone https://github.com/your-username/Rhythmic-ETL.git
   cd Rhythmic-ETL
   ```

4. Thiết lập và khởi động Airflow:
   ```bash
   cd airflow
   mkdir -p logs plugins dags config
   
   # Tạo file config/airflow.cfg từ tài liệu
   vi config/airflow.cfg
   # Sao chép nội dung từ docs/airflow_optimization.md

   # Thiết lập biến môi trường
   echo "AIRFLOW_UID=$(id -u)" > .env
   
   # Khởi động Airflow
   docker-compose up -d
   ```

5. Tạo các DAG:
   ```bash
   cd dags
   
   # Tạo DAG cho GCS to BigQuery
   vi gcs_to_bigquery.py
   
   # Tạo DAG để trigger dbt
   vi trigger_dbt.py
   ```

### Bước 8: Thiết lập dbt

1. Vẫn trên Airflow VM:
   ```bash
   cd ~/Rhythmic-ETL
   mkdir -p dbt
   cd dbt
   ```

2. Khởi tạo dbt project:
   ```bash
   dbt init rhythmic_dbt
   cd rhythmic_dbt
   ```

3. Cấu hình kết nối đến BigQuery trong `~/.dbt/profiles.yml`:
   ```yaml
   rhythmic_dbt:
     target: dev
     outputs:
       dev:
         type: bigquery
         method: service-account
         project: rhythmic-etl-project
         dataset: rhythmic_dataset
         keyfile: /path/to/service-account-key.json
         threads: 1
         timeout_seconds: 300
   ```

4. Tạo các model dbt:
   ```bash
   mkdir -p models/staging models/marts
   
   # Tạo models staging
   vi models/staging/stg_listen_events.sql
   vi models/staging/stg_page_view_events.sql
   vi models/staging/stg_auth_events.sql
   
   # Tạo models marts
   vi models/marts/dim_users.sql
   vi models/marts/dim_songs.sql
   vi models/marts/fact_listens.sql
   
   # Định nghĩa schema
   vi models/schema.yml
   ```

5. Chạy dbt để kiểm tra:
   ```bash
   dbt debug
   dbt run
   ```

### Bước 9: Theo dõi và quản lý chi phí

1. Thiết lập cảnh báo ngân sách:
   ```bash
   cd ~/Rhythmic-ETL/scripts
   chmod +x budget_alert.sh
   ./budget_alert.sh rhythmic-etl-project 10 your-email@example.com
   ```

2. Tạo lịch tắt VM tự động khi không sử dụng:
   ```bash
   chmod +x vm_control.sh
   
   # Thêm vào crontab để tắt VM lúc 7 giờ tối và bật lúc 8 giờ sáng
   crontab -e
   
   # Thêm các dòng sau:
   0 19 * * * /home/your-username/Rhythmic-ETL/scripts/vm_control.sh rhythmic-etl-project us-central1-a stop
   0 8 * * * /home/your-username/Rhythmic-ETL/scripts/vm_control.sh rhythmic-etl-project us-central1-a start
   ```

### Bước 10: Kiểm tra toàn bộ hệ thống

1. Kiểm tra Kafka:
   ```bash
   ssh kafka-vm
   cd Rhythmic-ETL/kafka
   docker-compose ps
   
   # Xem các messages đang được tạo
   docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic listen_events --from-beginning --max-messages 5
   ```

2. Kiểm tra Flink:
   ```bash
   ssh flink-vm
   cd Rhythmic-ETL/flink
   docker-compose ps
   
   # Truy cập Flink Dashboard
   # Mở trình duyệt và truy cập: http://[FLINK_VM_IP]:8081
   ```

3. Kiểm tra Airflow:
   ```bash
   ssh airflow-vm
   cd Rhythmic-ETL/airflow
   docker-compose ps
   
   # Truy cập Airflow UI
   # Mở trình duyệt và truy cập: http://[AIRFLOW_VM_IP]:8080
   ```

4. Kiểm tra dữ liệu trong BigQuery:
   - Truy cập [BigQuery Console](https://console.cloud.google.com/bigquery)
   - Truy vấn dữ liệu từ các bảng đã tạo
