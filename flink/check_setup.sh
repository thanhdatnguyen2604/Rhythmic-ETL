#!/bin/bash

echo "Kiểm tra cài đặt Flink và Python..."

echo "1. Kiểm tra phiên bản Python trong container"
docker-compose exec jobmanager python3 --version

echo "2. Kiểm tra các thư viện Python"
docker-compose exec jobmanager pip3 list | grep -E "flink|kafka|google"

echo "3. Kiểm tra các file Python jobs"
docker-compose exec jobmanager ls -la /opt/flink/jobs/

echo "4. Kiểm tra quyền thực thi"
docker-compose exec jobmanager stat -c "%a %n" /opt/flink/jobs/

echo "5. Kiểm tra nội dung file stream_all_events.py"
docker-compose exec jobmanager head -n 20 /opt/flink/jobs/stream_all_events.py

echo "Kiểm tra hoàn tất. Nếu mọi thứ đều OK, bạn có thể chạy run_jobs.sh để khởi động Flink jobs." 