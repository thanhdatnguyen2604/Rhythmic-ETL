#!/bin/bash

echo "=== Bắt đầu chạy Flink jobs ==="

# Kiểm tra xem containers đã chạy chưa
echo -e "\n1. Kiểm tra trạng thái containers..."
if ! docker-compose ps | grep -q "jobmanager.*Up"; then
    echo "Jobmanager chưa chạy. Bắt đầu khởi động containers..."
    docker-compose up -d
    
    # Đợi containers khởi động
    echo "Đợi containers khởi động..."
    sleep 10
fi

# Kiểm tra lại trạng thái
if ! docker-compose ps | grep -q "jobmanager.*Up"; then
    echo "Jobmanager vẫn chưa khởi động. Vui lòng kiểm tra logs."
    docker-compose logs jobmanager
    exit 1
fi

echo -e "\n2. Đảm bảo cấu hình đúng..."
# Kiểm tra biến môi trường
KAFKA_BROKER=${KAFKA_BROKER:-kafka-vm:9092}
GCS_BUCKET=${GCS_BUCKET:-rhythmic-events}
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-/opt/flink/secrets/gcp-credentials.json}

# Hiển thị thông tin
echo "KAFKA_BROKER: $KAFKA_BROKER"
echo "GCS_BUCKET: $GCS_BUCKET" 
echo "GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"

# Đảm bảo credentials tồn tại
if [ ! -f "secrets/gcp-credentials.json" ]; then
    echo "ERROR: GCP credentials không tồn tại tại secrets/gcp-credentials.json"
    echo "Vui lòng tạo file credentials trước khi chạy jobs."
    exit 1
fi

echo -e "\n3. Chạy Flink job chính (stream_all_events.py)..."
docker exec -it jobs-builder python3 /opt/flink/jobs/stream_all_events.py

echo -e "\n4. Kiểm tra trạng thái job..."
docker-compose exec jobmanager flink list

echo -e "\n=== Hoàn tất khởi động jobs ==="
echo "Bạn có thể kiểm tra UI Flink tại: http://localhost:8081"
echo "Bạn có thể kiểm tra logs bằng: docker-compose logs -f jobmanager" 