#!/bin/bash

# Tạo cấu trúc thư mục
mkdir -p data/{zookeeper,kafka,eventsim} config

# Tải Million Song Dataset Subset
echo "Tải Million Song Dataset Subset..."
wget https://storage.googleapis.com/million-song-dataset-subset/million-song-subset.zip -O data/eventsim/million-song-subset.zip

# Giải nén dữ liệu
echo "Giải nén dữ liệu..."
unzip data/eventsim/million-song-subset.zip -d data/eventsim/MillionSongSubset

# Xóa file zip
rm data/eventsim/million-song-subset.zip

# Tạo file config.json
echo "Tạo file config.json..."
cat > data/eventsim/config.json << EOF
{
    "users": 1000,
    "songs": 10000,
    "artists": 1000,
    "sessions_per_user": 100,
    "session_length": 3600,
    "session_interval": 86400,
    "song_length": 180,
    "song_interval": 300
}
EOF

echo "Chuẩn bị dữ liệu hoàn tất!" 