#!/bin/bash

echo "===== Kiểm tra cài đặt Flink-VM ====="

# Kiểm tra Docker và Docker Compose
echo -e "\n1. Kiểm tra Docker và Docker Compose..."
docker --version
docker-compose --version

# Kiểm tra thư mục
echo -e "\n2. Kiểm tra cấu trúc thư mục..."
mkdir -p data/checkpoints
mkdir -p secrets
ls -la data
ls -la secrets

# Kiểm tra kết nối Kafka
echo -e "\n3. Kiểm tra kết nối Kafka..."
KAFKA_HOST=${KAFKA_HOST:-"kafka-vm"}
KAFKA_PORT=${KAFKA_PORT:-9092}

echo "Đang thử kết nối đến $KAFKA_HOST:$KAFKA_PORT..."
nc -z -v -w5 $KAFKA_HOST $KAFKA_PORT
if [ $? -ne 0 ]; then
    echo "CẢNH BÁO: Không thể kết nối đến Kafka ở $KAFKA_HOST:$KAFKA_PORT"
else
    echo "Kết nối Kafka thành công!"
fi

# Kiểm tra GCP credentials
echo -e "\n4. Kiểm tra GCP credentials..."
if [ -f secrets/cred.json ]; then
    echo "File credentials GCP đã tồn tại"
    jq -r '.project_id' secrets/cred.json 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "CẢNH BÁO: File credentials không phải định dạng JSON hợp lệ"
    fi
else
    echo "CẢNH BÁO: File credentials GCP không tồn tại tại secrets/cred.json"
    echo "Bạn cần tạo file credentials để lưu dữ liệu vào GCS"
fi

# Kiểm tra biến môi trường
echo -e "\n5. Kiểm tra biến môi trường..."
echo "KAFKA_BROKER=${KAFKA_BROKER:-không được thiết lập, sẽ dùng mặc định 'kafka-vm:9092'}"
echo "GCS_BUCKET=${GCS_BUCKET:-không được thiết lập, sẽ dùng mặc định 'rhythmic-bucket'}"
echo "GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-không được thiết lập, sẽ dùng mặc định '/opt/flink/secrets/cred.json'}"

# Kiểm tra Docker Compose config
echo -e "\n6. Kiểm tra cấu hình Docker Compose..."
docker-compose config

# Kiểm tra các container đang chạy
echo -e "\n7. Kiểm tra các container đang chạy..."
docker-compose ps

if docker-compose ps | grep -q "Up"; then
    echo -e "\n8. Kiểm tra phiên bản Python trong container..."
    docker-compose exec jobmanager python3 --version

    echo -e "\n9. Kiểm tra các thư viện Python..."
    docker-compose exec jobmanager pip3 list | grep -E "flink|kafka|google"

    echo -e "\n10. Kiểm tra các file Python jobs..."
    docker-compose exec jobmanager ls -la /opt/flink/jobs/
    
    echo -e "\n11. Kiểm tra JAR files..."
    docker-compose exec jobmanager ls -la /opt/flink/lib/flink-*
fi

echo -e "\n===== Kiểm tra hoàn tất ====="
echo "Nếu mọi thứ đều OK, bạn có thể chạy ./run_jobs.sh để bắt đầu các Flink jobs" 