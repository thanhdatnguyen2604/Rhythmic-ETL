# Tối ưu Kafka cho môi trường giới hạn tài nguyên

## Cách hoạt động và sử dụng

Apache Kafka là một nền tảng phân tán để lưu trữ và xử lý các luồng dữ liệu thời gian thực. Trong dự án Rhythmic-ETL, Kafka đóng vai trò làm lớp trung gian (broker) giữa các nguồn dữ liệu (producers) và các ứng dụng xử lý (consumers). Tuy nhiên, khi chạy trên môi trường giới hạn tài nguyên như VM e2-micro, các cấu hình mặc định của Kafka có thể không phù hợp.

### Các cấu hình tối ưu đã thực hiện:

1. **Giảm số lượng partition xuống 1 cho mỗi topic**
   ```properties
   num.partitions=1
   ```
   - Mỗi partition yêu cầu tài nguyên riêng và tạo ra các file riêng biệt trên ổ đĩa
   - Với dữ liệu mẫu hoặc dữ liệu kiểm thử, một partition là đủ

2. **Giảm kích thước segment file**
   ```properties
   log.segment.bytes=100000000  # Khoảng 100MB
   ```
   - Segment file nhỏ hơn giúp quản lý tài nguyên tốt hơn
   - Giảm tải cho hệ thống file khi xử lý các segment

3. **Giảm retention period**
   ```properties
   log.retention.hours=24
   ```
   - Dữ liệu chỉ được giữ lại trong 24 giờ, phù hợp cho mục đích kiểm thử
   - Giảm lượng không gian đĩa cần thiết

4. **Giảm bộ nhớ cho Java heap**
   ```
   KAFKA_HEAP_OPTS="-Xmx512M -Xms256M"
   ```
   - Giới hạn tổng bộ nhớ Kafka sử dụng, phù hợp với VM e2-micro (1GB RAM)
   - Cân bằng giữa hiệu suất và khả năng ổn định

### Cách triển khai:

1. Thiết lập cấu hình trong `server.properties`
2. Thiết lập biến môi trường trong Docker Compose:
   ```yaml
   KAFKA_HEAP_OPTS: "-Xmx512M -Xms256M"
   ```
3. Sử dụng volumes để mount cấu hình và dữ liệu:
   ```yaml
   volumes:
     - ./data/kafka:/var/lib/kafka/data
     - ./config/server.properties:/opt/kafka/config/server.properties
   ```

## Mục đích và tính năng

### Mục đích của tối ưu:

1. **Giảm thiểu sử dụng bộ nhớ**
   - Kafka mặc định có thể sử dụng 1GB+ RAM
   - Cấu hình tối ưu giúp giảm xuống khoảng 500MB
   - Cho phép chạy cùng với các ứng dụng khác trên VM e2-micro

2. **Hạn chế sử dụng ổ đĩa**
   - Giảm retention period và log size giúp kiểm soát dung lượng đĩa
   - Phù hợp với ổ đĩa 10GB được cấu hình trong Terraform

3. **Cân bằng hiệu suất và sự ổn định**
   - Vẫn duy trì khả năng xử lý dữ liệu stream cho mục đích kiểm thử
   - Tránh lỗi OutOfMemory và crash hệ thống

4. **Tối ưu chi phí GCP**
   - Cho phép sử dụng VM e2-micro (miễn phí trong free tier) thay vì e2-standard-4
   - Tiết kiệm khoảng 75% chi phí VM

### Tính năng vẫn được bảo toàn:

1. **Khả năng xử lý stream dữ liệu thời gian thực**
   - Vẫn hỗ trợ producer/consumer model
   - Duy trì khả năng lưu trữ và chuyển tiếp message

2. **Tính sẵn sàng cao**
   - Cấu hình `restart: unless-stopped` trong Docker Compose
   - Tự động khởi động lại nếu gặp sự cố

3. **Tương thích với Flink**
   - Vẫn cho phép Flink đọc dữ liệu từ các topic
   - Không thay đổi giao thức hoặc format message

4. **Khả năng mở rộng**
   - Cấu hình có thể dễ dàng điều chỉnh khi nâng cấp VM
   - Có thể tăng số lượng partition khi cần xử lý dữ liệu lớn hơn

### Giới hạn:

1. Không phù hợp cho môi trường sản xuất với lưu lượng cao
2. Giới hạn số lượng consumer trong cùng một consumer group do chỉ có 1 partition
3. Hiệu suất xử lý có thể bị giảm khi lưu lượng tăng đột biến 