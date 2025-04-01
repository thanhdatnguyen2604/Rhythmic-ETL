# Flink ETL Jobs

Thư mục này chứa các Flink jobs để xử lý dữ liệu streaming từ Kafka và lưu vào Google Cloud Storage (GCS).

## Cấu trúc thư mục

```
flink/
├── config/                 # Cấu hình Flink
├── data/                   # Dữ liệu Flink
│   └── checkpoints/       # Checkpoints
├── jobs/                  # Python Flink jobs
│   ├── schema.py          # Định nghĩa schema cho các sự kiện
│   ├── streaming_functions.py  # Hàm xử lý streaming
│   └── stream_all_events.py   # Job chính
├── secrets/               # Thư mục chứa credentials
│   └── cred.json         # GCP Service Account key
├── Dockerfile.jobs        # Dockerfile cho Flink jobs
├── docker-compose.yml     # Cấu hình Docker Compose
├── run_jobs.sh           # Script chạy jobs
├── run_local.sh          # Script chạy trực tiếp (không dùng Docker)
├── check_setup.sh        # Script kiểm tra cài đặt
└── README.md             # File này
```

## Tiền điều kiện

1. **Docker & Docker Compose**: Cần cài đặt trên VM
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose
   sudo usermod -aG docker $USER
   ```

2. **GCP Credentials**: Cần file Service Account JSON để kết nối tới GCS
   ```bash
   # Tạo thư mục secrets
   mkdir -p secrets
   
   # Copy file credentials vào thư mục secrets
   # Đặt tên file là cred.json
   cp /path/to/service-account-key.json secrets/cred.json
   ```

3. **Kết nối mạng**: VM cần kết nối được đến Kafka VM
   ```bash
   # Kiểm tra kết nối
   nc -z -v kafka-vm 9092
   ```

## Các bước triển khai

1. **Clone repository**:
   ```bash
   git clone <repository_url>
   cd Rhythmic-ETL
   ```

2. **Thiết lập thư mục và phân quyền**:
   ```bash
   cd flink
   mkdir -p data/checkpoints secrets
   chmod +x *.sh
   ```

3. **Copy credentials GCP**:
   ```bash
   # Copy file credentials vào thư mục secrets
   cp /path/to/service-account-key.json secrets/cred.json
   ```

4. **Build và khởi động containers**:
   ```bash
   docker-compose up -d --build
   ```

5. **Kiểm tra cài đặt**:
   ```bash
   ./check_setup.sh
   ```
   
6. **Chạy Flink jobs**:
   ```bash
   ./run_jobs.sh
   ```

## Xử lý sự cố

### 1. Lỗi kết nối Kafka

Nếu không thể kết nối đến Kafka:

```
CẢNH BÁO: Không thể kết nối đến Kafka ở kafka-vm:9092
```

**Giải pháp**:
- Kiểm tra Kafka VM đã chạy chưa: `ssh kafka-vm "docker-compose ps"`
- Kiểm tra cấu hình mạng: `ping kafka-vm`
- Kiểm tra firewall: `sudo ufw status`

### 2. Lỗi credentials GCP

Nếu không tìm thấy credentials:

```
GOOGLE_APPLICATION_CREDENTIALS không tồn tại
```

**Giải pháp**:
- Copy file credentials vào đúng vị trí: `cp /path/to/service-account-key.json secrets/cred.json`
- Hoặc thiết lập biến môi trường trước khi chạy:
  ```bash
  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
  ./run_jobs.sh
  ```

### 3. Lỗi Python

Nếu gặp lỗi `No module named...`:

**Giải pháp**:
- Kiểm tra Docker container đã được build đúng chưa: `docker-compose build --no-cache`
- Kiểm tra thư viện: `docker-compose exec jobmanager pip list`

## Giám sát

- **Web UI**: Truy cập http://flink-vm:8081 để xem Flink Web UI
- **Logs**: `docker-compose logs jobmanager`
- **Trạng thái job**: `docker-compose exec jobmanager flink list`

## Dọn dẹp

```bash
# Dừng các container
docker-compose down

# Xóa dữ liệu (nếu cần)
rm -rf data/* secrets/*
``` 