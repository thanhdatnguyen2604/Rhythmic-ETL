# Kafka và Eventsim Setup

Thư mục này chứa cấu hình và script để chạy Kafka và Eventsim trên kafka-vm.

## Cấu trúc thư mục

```
kafka/
├── config/
│   └── server.properties    # Cấu hình Kafka
├── data/                    # Thư mục dữ liệu (sẽ được tạo khi chạy prepare_data.sh)
│   ├── zookeeper/          # Dữ liệu Zookeeper
│   ├── kafka/              # Dữ liệu Kafka
│   └── eventsim/           # Dữ liệu Eventsim và Million Song Dataset
├── Dockerfile.eventsim     # Dockerfile cho Eventsim
├── docker-compose.yml      # Cấu hình Docker Compose
├── prepare_data.sh         # Script chuẩn bị dữ liệu
├── requirements.txt        # Python dependencies
└── README.md              # Tài liệu này
```

## Các bước triển khai trên kafka-vm

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
   - Tải Million Song Dataset (khoảng 1.8GB) từ nguồn chính thức
   - Giải nén dataset vào thư mục data/eventsim/MillionSongSubset
   - Tạo file cấu hình cho Kafka và Eventsim
   - Cấp quyền truy cập cho các thư mục

4. Kiểm tra dữ liệu đã tải:
   ```bash
   # Kiểm tra kích thước dataset
   du -sh data/eventsim/MillionSongSubset
   
   # Kiểm tra số lượng file .h5
   find data/eventsim/MillionSongSubset -name "*.h5" | wc -l
   ```

5. Build và khởi động các container:
   ```bash
   docker-compose up -d --build
   ```

6. Kiểm tra trạng thái:
   ```bash
   docker-compose ps
   ```

7. Xem logs:
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

## Lưu ý quan trọng

- **Dữ liệu**: Million Song Dataset sẽ được tải về khi chạy `prepare_data.sh` trên kafka-vm
- **Dung lượng**: Cần ít nhất 4GB dung lượng trống (1.8GB cho dataset + 2GB cho dữ liệu Kafka)
- **RAM**: Các container cần ít nhất 2GB RAM để hoạt động tốt
- **Thời gian**: Quá trình tải và giải nén dataset có thể mất 5-10 phút tùy thuộc vào tốc độ mạng 