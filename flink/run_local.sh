#!/bin/bash

# Cài đặt dependencies nếu chưa có
echo "Kiểm tra và cài đặt dependencies..."
if ! command -v python3 &> /dev/null; then
    echo "Cài đặt Python 3..."
    sudo apt update
    sudo apt install -y python3 python3-pip
fi

if [ ! -f /usr/bin/python ]; then
    echo "Tạo symbolic link từ python3 đến python..."
    sudo ln -sf /usr/bin/python3 /usr/bin/python
fi

# Cài đặt Python libraries
echo "Cài đặt Python libraries..."
pip3 install --user apache-flink kafka-python google-cloud-storage

# Thiết lập biến môi trường
export PYFLINK_EXECUTABLE=python3
export PYTHONPATH=$PYTHONPATH:$(pwd)

# Chạy Flink job
echo "Chạy Flink job..."
cd jobs
flink run -py stream_all_events.py -pym stream_all_events

# Kiểm tra trạng thái
echo "Kiểm tra trạng thái jobs..."
flink list 