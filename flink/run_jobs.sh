#!/bin/bash

# Kiểm tra thư mục cần thiết
echo "Kiểm tra thư mục cần thiết..."
mkdir -p data/checkpoints
mkdir -p secrets

# Kiểm tra credentials
if [ ! -f secrets/cred.json ]; then
    echo "CẢNH BÁO: File credentials GCP không tồn tại tại secrets/cred.json"
    echo "Dữ liệu sẽ không được lưu vào GCS. Hãy đặt file credential vào thư mục secrets"
fi

# Kiểm tra kết nối Kafka
echo "Kiểm tra kết nối Kafka..."
KAFKA_HOST=${KAFKA_HOST:-"kafka-vm"}
KAFKA_PORT=${KAFKA_PORT:-9092}

echo "Đang thử kết nối đến $KAFKA_HOST:$KAFKA_PORT..."
nc -z -v -w5 $KAFKA_HOST $KAFKA_PORT
if [ $? -ne 0 ]; then
    echo "CẢNH BÁO: Không thể kết nối đến Kafka ở $KAFKA_HOST:$KAFKA_PORT"
    echo "Hãy đảm bảo Kafka đang chạy và có thể kết nối được từ VM này"
    echo "Tiếp tục nhưng job có thể không nhận được dữ liệu"
else
    echo "Kết nối Kafka thành công!"
fi

# Đợi Flink job manager khởi động
echo "Đợi Flink job manager khởi động..."
sleep 10

# Kiểm tra trạng thái job manager
echo "Kiểm tra trạng thái job manager..."
docker-compose ps jobmanager
if [ $? -ne 0 ]; then
    echo "LỖI: Job manager không chạy. Hãy chạy 'docker-compose up -d' trước!"
    exit 1
fi

# Cấu hình Python path
echo "Cấu hình Python path..."
docker-compose exec jobmanager bash -c "if [ ! -f /usr/bin/python ]; then ln -sf /usr/bin/python3 /usr/bin/python; fi"

# Chạy stream_all_events.py
echo "Chạy stream_all_events.py..."
docker-compose exec -e GOOGLE_APPLICATION_CREDENTIALS=/opt/flink/secrets/cred.json jobmanager flink run -py /opt/flink/jobs/stream_all_events.py -pym stream_all_events

# Kiểm tra trạng thái jobs
echo "Kiểm tra trạng thái jobs..."
docker-compose exec jobmanager flink list 