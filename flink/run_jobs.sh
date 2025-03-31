#!/bin/bash

# Đợi Flink job manager khởi động
echo "Đợi Flink job manager khởi động..."
sleep 10

# Chạy các Flink jobs
echo "Chạy Flink jobs..."

# Chạy stream_all_events.py
echo "Chạy stream_all_events.py..."
docker-compose exec jobmanager flink run -py /opt/flink/jobs/stream_all_events.py

# Kiểm tra trạng thái jobs
echo "Kiểm tra trạng thái jobs..."
docker-compose exec jobmanager flink list 