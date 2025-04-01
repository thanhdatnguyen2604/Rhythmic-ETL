# Flink Jobs Setup

Thư mục này chứa cấu hình và script để chạy Flink jobs trên flink-vm.

## Cấu trúc thư mục

```
flink/
├── config/                 # Cấu hình Flink
├── data/                   # Dữ liệu Flink
│   └── checkpoints/       # Checkpoints
├── jobs/                  # Python Flink jobs
│   ├── schema.py
│   ├── streaming_functions.py
│   └── stream_all_events.py
├── Dockerfile.jobs        # Dockerfile cho Flink jobs
├── docker-compose.yml     # Cấu hình Docker Compose
└── run_jobs.sh           # Script chạy jobs
```

## Các bước triển khai trên flink-vm

1. Clone repository và di chuyển vào thư mục flink:
   ```bash
   git clone <repository_url>
   cd flink
   ```

2. Tạo thư mục cho checkpoints:
   ```bash
   mkdir -p data/checkpoints
   ```

3. Cấp quyền thực thi cho script:
   ```bash
   chmod +x run_jobs.sh
   ```

4. Build và khởi động các container:
   ```bash
   docker-compose up -d --build
   ```

5. Kiểm tra trạng thái:
   ```bash
   docker-compose ps
   ```

6. Truy cập Flink Web UI:
   - Mở trình duyệt và truy cập: http://localhost:8081

7. Chạy Flink jobs:
   ```bash
   ./run_jobs.sh
   ```

## Kiểm tra hoạt động

1. Xem logs của job manager:
   ```bash
   docker-compose logs jobmanager
   ```

2. Xem logs của task manager:
   ```bash
   docker-compose logs taskmanager
   ```

3. Kiểm tra trạng thái jobs:
   ```bash
   docker-compose exec jobmanager flink list
   ```

## Dừng và xóa

1. Dừng các container:
   ```bash
   docker-compose down
   ```

2. Xóa dữ liệu (nếu cần):
   ```bash
   rm -rf data/checkpoints/*
   ```

## Lưu ý quan trọng

- **Python Environment**: Đã được cấu hình sẵn trong Dockerfile.jobs
- **Memory**: Các container cần ít nhất 2GB RAM để hoạt động tốt
- **Checkpoints**: Được lưu trong thư mục data/checkpoints
- **Web UI**: Có thể truy cập qua port 8081 