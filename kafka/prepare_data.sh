#!/bin/bash

# Tạo cấu trúc thư mục
mkdir -p data/{zookeeper,kafka,eventsim}

# Tải Million Song Dataset Subset
echo "Tải Million Song Dataset Subset..."
wget http://labrosa.ee.columbia.edu/~dpwe/tmp/millionsongsubset.tar.gz -O data/millionsongsubset.tar.gz

# Giải nén dữ liệu
echo "Giải nén dữ liệu..."
tar -xzf data/millionsongsubset.tar.gz -C data

# Xóa file tar.gz
rm data/millionsongsubset.tar.gz

# Tạo file config.json với cấu hình phù hợp với HDF5
echo "Tạo file config.json..."
cat > data/config.json << EOF
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

# Kiểm tra cấu trúc dữ liệu
echo "Kiểm tra cấu trúc dữ liệu..."
find data/MillionSongSubset -name "*.h5" | head -n 5

echo "Chuẩn bị dữ liệu hoàn tất!" 