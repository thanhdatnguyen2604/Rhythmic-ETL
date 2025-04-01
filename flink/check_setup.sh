#!/bin/bash

echo "=== Kiểm tra môi trường Flink ==="

# 1. Kiểm tra thư mục cần thiết
echo -e "\n1. Kiểm tra thư mục..."
for dir in config jobs secrets checkpoints savepoints; do
    if [ -d "$dir" ]; then
        echo "✓ Thư mục $dir tồn tại"
    else
        echo "✗ Thư mục $dir không tồn tại"
        mkdir -p "$dir"
        echo "  Đã tạo thư mục $dir"
    fi
done

# 2. Kiểm tra file cấu hình
echo -e "\n2. Kiểm tra file cấu hình..."
if [ -f "config/flink-conf.yaml" ]; then
    echo "✓ File flink-conf.yaml tồn tại"
else
    echo "✗ File flink-conf.yaml không tồn tại"
    cp /opt/flink/conf/flink-conf.yaml config/
    echo "  Đã tạo file flink-conf.yaml"
fi

# 3. Kiểm tra credentials
echo -e "\n3. Kiểm tra credentials..."
if [ -f "secrets/gcp-credentials.json" ]; then
    echo "✓ File credentials tồn tại"
    # Kiểm tra quyền
    if [ -r "secrets/gcp-credentials.json" ]; then
        echo "✓ File credentials có quyền đọc"
    else
        echo "✗ File credentials không có quyền đọc"
        chmod 644 secrets/gcp-credentials.json
    fi
else
    echo "✗ File credentials không tồn tại"
    echo "  Vui lòng thêm file gcp-credentials.json vào thư mục secrets/"
    exit 1
fi

# 4. Kiểm tra Python jobs
echo -e "\n4. Kiểm tra Python jobs..."
if [ -f "jobs/requirements.txt" ]; then
    echo "✓ File requirements.txt tồn tại"
    echo "  Các thư viện cần thiết:"
    cat jobs/requirements.txt
else
    echo "✗ File requirements.txt không tồn tại"
    exit 1
fi

# 5. Kiểm tra các file Python
echo -e "\n5. Kiểm tra các file Python..."
for file in jobs/*.py; do
    if [ -f "$file" ]; then
        echo "✓ File $(basename "$file") tồn tại"
        if [ -x "$file" ]; then
            echo "  ✓ Có quyền thực thi"
        else
            echo "  ✗ Không có quyền thực thi"
            chmod +x "$file"
        fi
    else
        echo "✗ File $(basename "$file") không tồn tại"
    fi
done

# 6. Kiểm tra Docker
echo -e "\n6. Kiểm tra Docker..."
if command -v docker &> /dev/null; then
    echo "✓ Docker đã cài đặt"
    docker --version
else
    echo "✗ Docker chưa cài đặt"
    exit 1
fi

# 7. Kiểm tra Docker Compose
echo -e "\n7. Kiểm tra Docker Compose..."
if command -v docker-compose &> /dev/null; then
    echo "✓ Docker Compose đã cài đặt"
    docker-compose --version
else
    echo "✗ Docker Compose chưa cài đặt"
    exit 1
fi

# 8. Kiểm tra các container
echo -e "\n8. Kiểm tra các container..."
docker-compose ps

# 9. Kiểm tra kết nối Kafka
echo -e "\n9. Kiểm tra kết nối Kafka..."
KAFKA_BROKER=${KAFKA_BROKER:-kafka-vm:9092}
if nc -z -w5 $(echo $KAFKA_BROKER | cut -d: -f1) $(echo $KAFKA_BROKER | cut -d: -f2); then
    echo "✓ Có thể kết nối đến Kafka broker"
else
    echo "✗ Không thể kết nối đến Kafka broker"
    echo "  Vui lòng kiểm tra:"
    echo "  1. Kafka broker có đang chạy không"
    echo "  2. Port 9092 có được mở không"
    echo "  3. KAFKA_BROKER có đúng không"
fi

echo -e "\n=== Kiểm tra hoàn tất ===" 