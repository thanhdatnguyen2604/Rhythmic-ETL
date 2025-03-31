#!/bin/bash

# Tạo cấu trúc thư mục
echo "Tạo cấu trúc thư mục..."
mkdir -p data/{zookeeper,kafka,eventsim} config

# Tải Million Song Dataset Subset
echo "Tải Million Song Dataset Subset..."
wget http://labrosa.ee.columbia.edu/~dpwe/tmp/millionsongsubset.tar.gz -O data/eventsim/millionsongsubset.tar.gz

# Giải nén dữ liệu
echo "Giải nén dữ liệu..."
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
find data/eventsim/MillionSongSubset -name "*.h5" | head -n 5

# Cấp quyền cho thư mục data
chmod -R 777 data

echo "Chuẩn bị dữ liệu hoàn tất!" 