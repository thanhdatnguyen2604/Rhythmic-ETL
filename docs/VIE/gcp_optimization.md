# Tối ưu Google Cloud Platform cho Chi phí Thấp

## Cách hoạt động và sử dụng

Google Cloud Platform (GCP) cung cấp một loạt dịch vụ đám mây để triển khai và vận hành ứng dụng. Trong dự án Rhythmic-ETL, chúng ta sử dụng nhiều dịch vụ GCP như Compute Engine, Cloud Storage, và BigQuery. Để tối ưu chi phí trong khi vẫn đảm bảo chức năng, một số chiến lược và kỹ thuật đã được triển khai.

### Các cấu hình tối ưu đã thực hiện:

1. **Thiết lập giới hạn chi tiêu hàng ngày/hàng tuần**
   - Sử dụng Billing Budget API để thiết lập và theo dõi ngân sách
   - Cảnh báo qua email khi đạt 50%, 80%, và 100% ngân sách

   ```bash
   ./scripts/budget_alert.sh [PROJECT_ID] [BUDGET_AMOUNT] [EMAIL]
   ```

2. **Sử dụng regional bucket thay vì multi-regional**
   ```terraform
   resource "google_storage_bucket" "rhythmic_bucket" {
     name     = var.gcs_bucket_name
     location = var.region  # Sử dụng region cụ thể thay vì multi-region
     # Cấu hình khác...
   }
   ```
   - Regional bucket có chi phí thấp hơn đáng kể
   - Phù hợp cho môi trường phát triển và kiểm thử

3. **Tắt VM khi không sử dụng**
   - Script tự động để bật/tắt VM dựa trên lịch hoặc theo yêu cầu
   ```bash
   ./scripts/vm_control.sh [PROJECT_ID] [ZONE] stop
   ```
   - Giảm đáng kể chi phí vì VM chỉ tính phí khi đang chạy
   - Preemptible VM được sử dụng để giảm thêm 75% chi phí

4. **Sử dụng preemptible VM**
   ```terraform
   scheduling {
     preemptible = true
     automatic_restart = false
   }
   ```
   - VM có thể bị dừng bởi Google sau 24 giờ hoặc khi cần tài nguyên
   - Chi phí thấp hơn 75-80% so với VM thông thường

### Cách triển khai:

1. **Thiết lập cảnh báo ngân sách**:
   - Chạy script `budget_alert.sh` với thông tin project, ngân sách và email
   - Xác nhận thiết lập trên GCP Billing Console

2. **Quản lý VM**:
   - Chạy script `vm_control.sh` để bật/tắt VM theo nhu cầu
   - Tích hợp vào crontab để tự động hóa theo lịch

3. **Cấu hình Terraform tối ưu**:
   - Sử dụng e2-micro (free tier) thay vì e2-standard-4
   - Thiết lập storage và network theo nhu cầu thực tế

## Mục đích và tính năng

### Mục đích của tối ưu:

1. **Tối đa hóa giá trị từ $300 credit miễn phí**
   - Kéo dài thời gian sử dụng tín dụng miễn phí từ 1 tháng lên 3-6 tháng
   - Tận dụng các dịch vụ free tier của GCP

2. **Tránh chi phí không mong muốn**
   - Theo dõi và cảnh báo sớm khi ngân sách gần đạt giới hạn
   - Ngăn chặn việc vô tình sử dụng các dịch vụ đắt tiền

3. **Cân bằng chi phí và hiệu suất**
   - Duy trì khả năng hoạt động của hệ thống với chi phí tối thiểu
   - Tối ưu hóa sử dụng tài nguyên cho nhu cầu phát triển và kiểm thử

4. **Tuân thủ nguyên tắc FinOps**
   - Tạo văn hóa nhận thức về chi phí trong phát triển đám mây
   - Sử dụng tài nguyên một cách có trách nhiệm

### Tính năng và lợi ích:

1. **Kiểm soát ngân sách chủ động**
   - Theo dõi chi phí thời gian thực
   - Nhận cảnh báo trước khi vượt quá ngân sách
   - Tránh "bill shock" vào cuối tháng

2. **Chi phí VM tối thiểu**
   - Sử dụng e2-micro (~$6/tháng) thay vì e2-standard-4 (~$70/tháng)
   - Tắt VM khi không sử dụng, chỉ trả tiền cho thời gian sử dụng thực tế
   - Preemptible VM giảm chi phí thêm 75%

3. **Tối ưu chi phí lưu trữ**
   - Regional bucket thay vì multi-regional (~40% rẻ hơn)
   - Giới hạn thời gian lưu trữ data trên BigQuery
   - Sử dụng nén và phân vùng để giảm kích thước dữ liệu

4. **Minh bạch chi phí**
   - Theo dõi chi phí theo dịch vụ và theo thời gian
   - Dễ dàng xác định thành phần chi phí cao

### Chiến lược tối ưu chi phí dài hạn:

1. **Lập lịch tự động bật/tắt VM**
   - Tắt VM vào buổi tối và cuối tuần
   - Chỉ chạy khi cần thiết cho phát triển hoặc demo

2. **Sử dụng VM spots cho xử lý batch**
   - Tận dụng VM chi phí thấp hơn cho công việc có thể bị gián đoạn
   - Thiết kế ứng dụng để xử lý việc VM có thể bị dừng

3. **Sử dụng BigQuery hiệu quả**
   - Xử lý dữ liệu trên GCS trước khi đưa vào BigQuery
   - Sử dụng materialized views để tối ưu truy vấn
   - Áp dụng phân vùng và cluster cho bảng BigQuery

4. **Thiết lập chu kỳ rà soát chi phí**
   - Đánh giá chi phí định kỳ hàng tuần
   - Xác định và tối ưu các dịch vụ tốn kém

### Giới hạn của cấu hình:

1. VM e2-micro có hiệu suất thấp, có thể gây ra độ trễ trong xử lý
2. Preemptible VM có thể bị dừng bất cứ lúc nào, cần thiết kế ứng dụng để xử lý các trường hợp này
3. Tắt VM định kỳ có thể không phù hợp cho các ứng dụng cần hoạt động liên tục
4. Regional bucket có độ bền và sẵn sàng thấp hơn multi-regional bucket