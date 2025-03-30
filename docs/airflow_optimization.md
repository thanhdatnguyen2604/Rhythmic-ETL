# Tối ưu Airflow cho môi trường giới hạn tài nguyên

## Cách hoạt động và sử dụng

Apache Airflow là một nền tảng lập lịch và điều phối các luồng công việc, được sử dụng để tự động hóa, lập lịch và giám sát các pipeline dữ liệu. Trong dự án Rhythmic-ETL, Airflow đóng vai trò quan trọng trong việc điều phối các công việc định kỳ như tạo external tables từ dữ liệu lưu trữ trên GCS, chạy các query BigQuery, và kích hoạt các transformation của dbt.

### Các cấu hình tối ưu đã thực hiện:

1. **Sử dụng LocalExecutor thay vì CeleryExecutor**
   ```ini
   executor = LocalExecutor
   ```
   - LocalExecutor chạy các task trong các process riêng biệt trên cùng một máy
   - Loại bỏ phụ thuộc vào Redis và Celery worker, giảm tài nguyên cần thiết

2. **Giảm số lượng worker**
   ```ini
   workers = 1
   ```
   - Giới hạn số lượng worker trong webserver để tiết kiệm tài nguyên
   - Giảm thiểu xử lý song song không cần thiết

3. **Tăng khoảng thời gian giữa các lần chạy DAG**
   ```ini
   min_file_process_interval = 60
   dag_dir_list_interval = 120
   ```
   - Giảm tần suất quét DAG files để giảm CPU và I/O
   - Tăng thời gian giữa các lần scheduler kiểm tra DAG

4. **Giảm logging level**
   ```ini
   logging_level = WARNING
   fab_logging_level = WARNING
   ```
   - Chỉ ghi log các cảnh báo và lỗi, bỏ qua thông tin debug
   - Giảm I/O đĩa và kích thước log file

### Cách triển khai:

1. Cấu hình Airflow trong file `airflow.cfg`
2. Thiết lập Docker Compose với các biến môi trường:
   ```yaml
   environment:
     AIRFLOW__CORE__EXECUTOR: LocalExecutor
     AIRFLOW__CORE__LOGGING_LEVEL: 'WARNING'
     AIRFLOW__CORE__DAG_CONCURRENCY: '2'
     AIRFLOW__CORE__MAX_ACTIVE_RUNS_PER_DAG: '1'
     # Các cấu hình khác...
   ```
3. Giới hạn bộ nhớ cho các container:
   ```yaml
   mem_limit: 512m
   ```

## Mục đích và tính năng

### Mục đích của tối ưu:

1. **Giảm thiểu sử dụng bộ nhớ**
   - Airflow mặc định cần 4GB+ RAM khi sử dụng CeleryExecutor
   - Cấu hình tối ưu giảm xuống khoảng 1GB với LocalExecutor
   - Thích hợp cho VM e2-micro với 1GB RAM

2. **Tối ưu hiệu suất CPU**
   - Giảm số lượng process chạy đồng thời
   - Giảm tần suất quét và xử lý DAG
   - Giảm overhead của việc logging quá mức

3. **Tiết kiệm không gian đĩa**
   - Giảm kích thước và số lượng log file
   - Quản lý hiệu quả hơn lưu trữ của PostgreSQL

4. **Cân bằng giữa độ tin cậy và tài nguyên**
   - Vẫn duy trì khả năng lập lịch và thực thi workflow
   - Giảm thiểu hiệu suất chỉ ở mức chấp nhận được

### Tính năng chính của Airflow vẫn được bảo toàn:

1. **Lập lịch và điều phối workflow**
   - Khả năng định nghĩa, lập lịch và thực thi các DAG
   - Hỗ trợ dependency giữa các task

2. **Giao diện web để giám sát**
   - Theo dõi trạng thái của các task và DAG
   - Xem logs và debug các vấn đề

3. **Tích hợp với GCP**
   - Kết nối với BigQuery, GCS, và các dịch vụ GCP khác
   - Sử dụng các operators cho GCP

4. **Khả năng retry và xử lý lỗi**
   - Tự động thử lại các task bị lỗi
   - Xử lý các trường hợp ngoại lệ

### Những thay đổi trong cách sử dụng:

1. **Lập lịch DAG với khoảng thời gian dài hơn**
   - Thay vì chạy mỗi giờ, có thể điều chỉnh sang 3-6 giờ
   - Tránh overlap giữa các lần chạy

2. **Phân tách DAG lớn thành nhiều DAG nhỏ hơn**
   - Mỗi DAG nên tập trung vào một nhiệm vụ cụ thể
   - Giảm phụ thuộc và phức tạp trong mỗi DAG

3. **Sử dụng sensor một cách thận trọng**
   - Tránh sử dụng sensor với polling liên tục
   - Tăng poke_interval để giảm tải lên hệ thống

4. **Tối ưu việc sử dụng XCom**
   - Giới hạn kích thước dữ liệu truyền qua XCom
   - Sử dụng bộ nhớ ngoài (GCS) cho dữ liệu lớn

### Giới hạn của cấu hình hiện tại:

1. Xử lý song song bị hạn chế (tối đa 2 task đồng thời)
2. Độ trễ cao hơn trong phát hiện và xử lý DAG mới
3. Không phù hợp cho workload phức tạp hoặc cần tài nguyên cao
4. Khả năng mở rộng bị hạn chế về số lượng DAG và task 