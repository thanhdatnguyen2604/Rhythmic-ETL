#!/bin/bash

# Đợi Flink job manager khởi động
echo "Đợi Flink job manager khởi động..."
sleep 10

# Chạy các Flink jobs
echo "Chạy Flink jobs..."

# Cấu hình Python path
echo "Cấu hình Python path..."
docker-compose exec jobmanager bash -c "if [ ! -f /usr/bin/python ]; then ln -sf /usr/bin/python3 /usr/bin/python; fi"

# Chạy stream_all_events.py
echo "Chạy stream_all_events.py..."
docker-compose exec jobmanager flink run -py /opt/flink/jobs/stream_all_events.py -pym stream_all_events

# Kiểm tra trạng thái jobs
echo "Kiểm tra trạng thái jobs..."
docker-compose exec jobmanager flink list 