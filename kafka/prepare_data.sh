#!/bin/bash

# Kiểm tra dung lượng ổ đĩa
echo "Kiểm tra dung lượng ổ đĩa..."
FREE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo "Dung lượng trống hiện tại: $FREE_SPACE"

# Tạo cấu trúc thư mục
echo "Tạo cấu trúc thư mục..."
mkdir -p data/{zookeeper,kafka,eventsim} config

# Tải Million Song Dataset Subset
echo "Tải Million Song Dataset Subset (khoảng 1.8GB)..."
echo "Nguồn: http://labrosa.ee.columbia.edu/~dpwe/tmp/millionsongsubset.tar.gz"
wget http://labrosa.ee.columbia.edu/~dpwe/tmp/millionsongsubset.tar.gz -O data/eventsim/millionsongsubset.tar.gz

# Kiểm tra file đã tải
if [ ! -f data/eventsim/millionsongsubset.tar.gz ]; then
    echo "Lỗi: Không thể tải dataset!"
    exit 1
fi

# Giải nén dữ liệu
echo "Giải nén dữ liệu (có thể mất vài phút)..."
tar -xzf data/eventsim/millionsongsubset.tar.gz -C data/eventsim

# Xóa file tar.gz
rm data/eventsim/millionsongsubset.tar.gz

# Tạo file config.json cho Eventsim
echo "Tạo file config.json cho Eventsim..."
cat > data/eventsim/config.json << EOF
{
    "users": 1000,
    "songs": 10000,
    "artists": 1000,
    "h5_data_path": "/data/MillionSongSubset",
    "sessions_per_user": 100,
    "session_length": 3600,
    "session_interval": 86400,
    "song_length": 180,
    "song_interval": 300
}
EOF

# Tạo file cấu hình Kafka
echo "Tạo file cấu hình Kafka..."
cat > config/server.properties << EOF
broker.id=1
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://kafka:9092
num.network.threads=2
num.io.threads=2
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/var/lib/kafka/data
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=24
log.segment.bytes=100000000
EOF

# Kiểm tra cấu trúc dữ liệu
echo "Kiểm tra cấu trúc dữ liệu..."
echo "Số lượng file .h5:"
find data/eventsim/MillionSongSubset -name "*.h5" | wc -l

echo "Kích thước thư mục MillionSongSubset:"
du -sh data/eventsim/MillionSongSubset

# Cấp quyền cho thư mục data
echo "Cấp quyền truy cập cho thư mục data..."
chmod -R 777 data

echo "Chuẩn bị dữ liệu hoàn tất!"
echo "Bạn có thể tiếp tục với lệnh: docker-compose up -d --build" 