# Sử dụng Million Song Dataset trong Rhythmic-ETL

## Giới thiệu
Million Song Dataset (MSD) là một tập dữ liệu âm nhạc miễn phí gồm các đặc trưng âm thanh và metadata cho một triệu bài hát phổ biến. Trong dự án Rhythmic-ETL, chúng ta sử dụng **Million Song Dataset Subset** (10,000 bài hát, 1.8GB) làm nguồn dữ liệu cho hệ thống streaming.

## Tải và chuẩn bị dữ liệu

1. Tải Million Song Dataset Subset từ website chính thức:
   ```bash
   ssh kafka-vm
   mkdir -p ~/Rhythmic-ETL/eventsim/data
   cd ~/Rhythmic-ETL/eventsim/data
   wget http://storage.googleapis.com/millionsongdataset/millionsongsubset.tar.gz
   tar -xzf millionsongsubset.tar.gz
   ```

2. Tải lên GCS bucket để lưu trữ lâu dài và chia sẻ giữa các VM:
   ```bash
   # Đảm bảo đã cài đặt gsutil và xác thực GCP
   gsutil -m cp -r ~/Rhythmic-ETL/eventsim/data/MillionSongSubset gs://${BUCKET_NAME}/datasets/
   ```

## Cấu hình Eventsim với Million Song Dataset

Cập nhật file `eventsim/docker-compose.yml` để sử dụng Million Song Dataset:

```yaml
version: '3'
services:
  eventsim:
    image: zachmandeville/eventsim:latest
    container_name: eventsim
    depends_on:
      - kafka
    volumes:
      - ./data:/data
    command: >
      --kafka-broker kafka:9092
      --song-data /data/MillionSongSubset
      --config /data/config.json
      --from-time 2023-01-01
      --nusers 1000
      --duration 24h
    networks:
      - kafka-network

networks:
  kafka-network:
    external: true
```

Tạo file cấu hình `eventsim/data/config.json`:

```json
{
  "kafkaConfig": {
    "bootstrap.servers": "kafka:9092"
  },
  "topics": {
    "listen_events": "listen_events",
    "page_view_events": "page_view_events",
    "auth_events": "auth_events"
  },
  "songDataPath": "/data/MillionSongSubset",
  "nUsers": 1000,
  "startTime": "2023-01-01T00:00:00Z",
  "endTime": "2023-01-02T00:00:00Z",
  "outputFormat": "json"
}
```

## Tích hợp với Flink

Flink job đã được cấu hình phù hợp trong `flink_jobs/schema.py` để xử lý dữ liệu từ Million Song Dataset:

```python
listen_event_schema = DataTypes.ROW([
    DataTypes.FIELD("listen_id", DataTypes.STRING()),
    DataTypes.FIELD("user_id", DataTypes.STRING()),
    DataTypes.FIELD("song_id", DataTypes.STRING()),  # ID từ Million Song Dataset
    DataTypes.FIELD("artist", DataTypes.STRING()),   # Nghệ sĩ từ Million Song Dataset
    DataTypes.FIELD("song", DataTypes.STRING()),     # Tên bài hát từ MSD
    DataTypes.FIELD("duration", DataTypes.DOUBLE()), # Thời lượng từ MSD
    DataTypes.FIELD("ts", DataTypes.BIGINT())        # Timestamp sự kiện
])
```
```

## 3. Điều chỉnh Machine Types cho các VM

### 1. VM cho Kafka: e2-small vs e2-medium

**Phân tích:**
- **e2-small**: 2 vCPU, 2GB RAM
  - Đủ cho Kafka với workload nhỏ (1000 users, 10,000 songs)
  - Chi phí: ~$12.41/tháng, hoặc ~$0.41/ngày
  - Với preemptible VM: ~$3.72/tháng, hoặc ~$0.12/ngày

- **e2-medium**: 2 vCPU, 4GB RAM
  - Tốt hơn cho Kafka với more stable performance
  - Chi phí: ~$24.82/tháng, hoặc ~$0.83/ngày
  - Với preemptible VM: ~$7.45/tháng, hoặc ~$0.25/ngày

**Khuyến nghị:** Sử dụng **e2-small** vì:
- Đủ cho workload testing 1-2 ngày
- Preemptible VM giúp tiết kiệm 70% chi phí
- 2GB RAM là đủ cho Kafka single-node với các cấu hình tối ưu đã áp dụng

### 2. VM cho Flink: e2-medium + 50GB disk

**Phân tích:**
- **e2-medium**: 2 vCPU, 4GB RAM
  - Phù hợp cho Flink với small-to-medium workloads
  - Chi phí: ~$24.82/tháng + Disk 50GB (~$5/tháng) = ~$29.82/tháng
  - Với preemptible VM: ~$7.45/tháng + Disk 50GB = ~$12.45/tháng, hoặc ~$0.41/ngày

**Khuyến nghị:** Đồng ý sử dụng **e2-medium** với 50GB disk vì:
- Flink cần memory cao hơn Spark khi xử lý windowed operations
- 50GB disk phù hợp để lưu trữ state và checkpoints
- Preemptible instance giảm chi phí đáng kể

### 3. VM cho Airflow: e2-micro

**Phân tích:**
- **e2-micro**: 2 vCPU (shared), 1GB RAM
  - Đủ cho Airflow với LocalExecutor và số lượng DAG giới hạn
  - Chi phí: ~$6.20/tháng, hoặc ~$0.21/ngày
  - Với preemptible VM: ~$1.86/tháng, hoặc ~$0.06/ngày

**Khuyến nghị:** Đồng ý sử dụng **e2-micro** vì:
- Airflow chỉ lập lịch và điều phối, không xử lý dữ liệu
- Đã được tối ưu với LocalExecutor, giảm tài nguyên cần thiết
- Chi phí rất thấp, đặc biệt với preemptible VM

### 4. GCS Bucket cho Million Song Dataset

**Cấu hình bổ sung:**
```terraform
# Tạo GCS Bucket cho Million Song Dataset
resource "google_storage_bucket" "msd_bucket" {
  name     = "${var.gcs_bucket_name}-msd"
  location = var.region
  force_destroy = true
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30  # Xóa dữ liệu sau 30 ngày để tiết kiệm chi phí
    }
    action {
      type = "Delete"
    }
  }
}
```

**Chi phí ước tính:**
- Storage: ~$0.02/GB/tháng cho standard storage
- 2GB (Million Song Subset) = ~$0.04/tháng

## Tổng chi phí ước tính cho 2 ngày sử dụng

Với preemptible VMs (tiết kiệm 70% chi phí VM):

1. Kafka VM (e2-small): ~$0.12/ngày × 2 = $0.24
2. Flink VM (e2-medium + 50GB disk): ~$0.41/ngày × 2 = $0.82
3. Airflow VM (e2-micro): ~$0.06/ngày × 2 = $0.12
4. GCS Storage: ~$0.04/tháng ÷ 30 × 2 = $0.00267
5. BigQuery: Free tier hàng tháng (1TB query, 10GB storage)

**Tổng chi phí ước tính: ~$1.18 cho 2 ngày**

Với non-preemptible VMs (chi phí tiêu chuẩn):

1. Kafka VM (e2-small): ~$0.41/ngày × 2 = $0.82
2. Flink VM (e2-medium + 50GB disk): ~$0.99/ngày × 2 = $1.98
3. Airflow VM (e2-micro): ~$0.21/ngày × 2 = $0.42
4. GCS Storage: ~$0.04/tháng ÷ 30 × 2 = $0.00267
5. BigQuery: Free tier hàng tháng

**Tổng chi phí ước tính (non-preemptible): ~$3.22 cho 2 ngày**

## Nguyên nhân gốc rễ của các vấn đề và cách phòng tránh

1. **Thiếu nhất quán trong các thành phần khi chuyển công nghệ**:
   - **Nguyên nhân**: Khi quyết định chuyển từ Spark sang Flink, không cập nhật đồng bộ tất cả các thành phần
   - **Phòng tránh**: Sử dụng issue tracker và checklist khi thay đổi công nghệ, kèm theo đánh giá tác động

2. **Tài liệu thiếu chi tiết về Million Song Dataset**:
   - **Nguyên nhân**: Không có hiểu biết đầy đủ về cách sử dụng dataset trong dự án
   - **Phòng tránh**: Tạo tài liệu chi tiết về data workflow từ đầu đến cuối, bao gồm tải, xử lý và lưu trữ

3. **Chưa tối ưu resource cho từng thành phần**:
   - **Nguyên nhân**: Không phân tích kỹ nhu cầu tài nguyên của từng công nghệ
   - **Phòng tránh**: Thực hiện load testing nhỏ để xác định nhu cầu tài nguyên thực tế trước khi triển khai

4. **Chi phí chưa được tính toán cụ thể**:
   - **Nguyên nhân**: Thiếu phân tích chi phí chi tiết cho từng thành phần
   - **Phòng tránh**: Sử dụng GCP Pricing Calculator trước khi triển khai và thiết lập cảnh báo chi phí

Bằng cách tuân thủ các thực tiễn tốt trên, dự án Rhythmic-ETL có thể được triển khai một cách hiệu quả về chi phí, đồng thời đảm bảo tính nhất quán và đáng tin cậy.