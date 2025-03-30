# Tối ưu Flink cho môi trường giới hạn tài nguyên

## Cách hoạt động và sử dụng

Apache Flink là một framework xử lý dữ liệu phân tán, hỗ trợ xử lý batch và stream với độ trễ thấp. Trong dự án Rhythmic-ETL, Flink thay thế Spark để xử lý dữ liệu streaming từ Kafka với hiệu suất tốt hơn trong môi trường hạn chế tài nguyên. Flink xử lý dữ liệu theo luồng thực sự (true streaming), trong khi Spark sử dụng mô hình micro-batch.

### Các cấu hình tối ưu đã thực hiện:

1. **Chạy ở chế độ standalone thay vì cluster**
   - Sử dụng kiến trúc đơn giản với 1 JobManager và 1 TaskManager
   - Phù hợp với mô hình triển khai trên một VM đơn lẻ

2. **Giảm số lượng task slot xuống 1**
   ```yaml
   taskmanager.numberOfTaskSlots: 1
   ```
   - Mỗi task slot tương ứng với một luồng xử lý song song
   - Giới hạn song song hóa để tiết kiệm tài nguyên

3. **Giảm JVM heap size**
   ```yaml
   taskmanager.memory.process.size: 500mb
   jobmanager.memory.process.size: 512mb
   ```
   - Giảm tổng lượng bộ nhớ Flink sử dụng
   - Cấu hình các thành phần bộ nhớ chi tiết để tối ưu

4. **Giảm bộ nhớ cho network buffer**
   ```yaml
   taskmanager.memory.network.fraction: 0.1
   taskmanager.memory.network.min: 32mb
   taskmanager.memory.network.max: 64mb
   ```
   - Network buffer được dùng để truyền dữ liệu giữa các task
   - Giảm kích thước buffer giúp tiết kiệm bộ nhớ

### Cách triển khai:

1. Cấu hình Flink trong file `flink-conf.yaml`
2. Thiết lập Docker Compose để chạy Flink standalone:
   ```yaml
   services:
     jobmanager:
       image: flink:latest
       # Cấu hình khác...
     
     taskmanager:
       image: flink:latest
       # Cấu hình khác...
   ```
3. Sử dụng volumes để mount cấu hình:
   ```yaml
   volumes:
     - ./config/flink-conf.yaml:/opt/flink/conf/flink-conf.yaml
   ```

## Mục đích và tính năng

### Mục đích của tối ưu:

1. **Giảm thiểu sử dụng bộ nhớ**
   - Flink mặc định có thể yêu cầu 1.5GB+ bộ nhớ
   - Cấu hình tối ưu giảm xuống khoảng 500MB cho TaskManager
   - Cho phép chạy trên VM e2-micro với 1GB RAM

2. **Tối ưu hiệu suất trong môi trường hạn chế**
   - Flink vốn là framework stream processing hiệu quả về bộ nhớ
   - Cấu hình tùy chỉnh giúp cân bằng hiệu suất và tài nguyên

3. **Đảm bảo xử lý dữ liệu thời gian thực**
   - Duy trì khả năng xử lý stream với độ trễ thấp
   - Sử dụng checkpointing với khoảng thời gian dài hơn (10 giây) để giảm tải

4. **Tối ưu chi phí GCP**
   - Cho phép chạy trên VM e2-micro với hiệu suất chấp nhận được
   - Tiết kiệm chi phí đáng kể so với yêu cầu VM lớn hơn

### Tính năng của Flink được tận dụng:

1. **True Streaming Processing**
   - Xử lý từng sự kiện ngay khi nó đến, không đợi batch
   - Giảm độ trễ xử lý so với mô hình micro-batch của Spark

2. **Quản lý trạng thái hiệu quả**
   - Flink có khả năng quản lý trạng thái nội bộ tốt hơn Spark Streaming
   - Hỗ trợ exactly-once processing với chi phí thấp hơn

3. **Cửa sổ thời gian linh hoạt**
   - Hỗ trợ cửa sổ tumbling, sliding và session windows
   - Xử lý dữ liệu phụ thuộc thời gian hiệu quả

4. **Khả năng khôi phục lỗi**
   - Checkpoint-based fault tolerance
   - Khả năng phục hồi từ trạng thái đã lưu

### Lợi thế của Flink so với Spark trong môi trường hạn chế:

1. **Hiệu quả bộ nhớ hơn**
   - Flink quản lý bộ nhớ ở mức JVM, không phụ thuộc vào GC của Java
   - Sử dụng serialized data format tiết kiệm bộ nhớ

2. **Tiêu thụ CPU thấp hơn**
   - Cơ chế điều độ task hiệu quả hơn
   - Giảm overhead của việc xử lý micro-batch

3. **Độ trễ thấp hơn**
   - True streaming giúp xử lý dữ liệu với độ trễ rất thấp
   - Quan trọng cho ứng dụng xử lý dữ liệu thời gian thực

### Giới hạn của cấu hình:

1. Giảm khả năng xử lý song song (parallelism)
2. Có thể bị quá tải khi lưu lượng dữ liệu tăng đột biến
3. Không tận dụng được đầy đủ khả năng mở rộng của Flink
4. Hạn chế số lượng trạng thái (state) có thể lưu trữ 