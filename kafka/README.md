# Kafka và Eventsim Setup

Thư mục này chứa cấu hình và script để chạy Kafka và Eventsim trên kafka-vm.

## Cấu trúc thư mục

```
kafka/
├── config/
│   └── server.properties    # Cấu hình Kafka
├── data/
│   ├── zookeeper/          # Dữ liệu Zookeeper
│   ├── kafka/              # Dữ liệu Kafka
│   └── eventsim/           # Dữ liệu Eventsim
│       ├── MillionSongSubset/  # Dataset
│       └── config.json     # Cấu hình Eventsim
├── Dockerfile.eventsim     # Dockerfile cho Eventsim
├── docker-compose.yml      # Cấu hình Docker Compose
├── prepare_data.sh         # Script chuẩn bị dữ liệu
├── requirements.txt        # Python dependencies
└── README.md              # Tài liệu này
```

## Các bước triển khai

1. Clone repository và di chuyển vào thư mục kafka:
   ```bash
   git clone <repository_url>
   cd kafka
   ```

2. Cấp quyền thực thi cho script:
   ```bash
   chmod +x prepare_data.sh
   ```

3. Chạy script chuẩn bị dữ liệu:
   ```bash
   ./prepare_data.sh
   ```
   Script này sẽ:
   - Tạo cấu trúc thư mục cần thiết
   - Tải và giải nén Million Song Dataset
   - Tạo file cấu hình cho Kafka và Eventsim

4. Build và khởi động các container:
   ```bash
   docker-compose up -d --build
   ```

5. Kiểm tra trạng thái:
   ```bash
   docker-compose ps
   ```

6. Xem logs:
   ```bash
   # Xem logs của tất cả các service
   docker-compose logs

   # Xem logs của một service cụ thể
   docker-compose logs kafka
   docker-compose logs eventsim
   ```

## Kiểm tra hoạt động

1. Kiểm tra Kafka topics:
   ```bash
   docker-compose exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092
   ```

2. Xem dữ liệu từ Eventsim:
   ```bash
   docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic listen_events --from-beginning --max-messages 5
   ```

## Dừng và xóa

1. Dừng các container:
   ```bash
   docker-compose down
   ```

2. Xóa dữ liệu (nếu cần):
   ```bash
   rm -rf data/*
   ```

## Lưu ý

- Đảm bảo có đủ dung lượng ổ đĩa cho dữ liệu
- Million Song Dataset có kích thước khoảng 1.8GB
- Các container cần ít nhất 2GB RAM để hoạt động tốt 