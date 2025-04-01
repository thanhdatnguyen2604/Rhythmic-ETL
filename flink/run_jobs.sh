#!/bin/bash

echo "=== Bắt đầu chạy Flink jobs ==="

# Check if containers are running
echo -e "\n1. Check container status..."
if ! docker-compose ps | grep -q "jobmanager.*Up"; then
    echo "Jobmanager is not running. Starting containers..."
    docker-compose up -d
    
    # Wait for containers to start
    echo "Waiting for containers to start..."
    sleep 10
fi

# Check again status
if ! docker-compose ps | grep -q "jobmanager.*Up"; then
    echo "Jobmanager is not running. Please check logs."
    docker-compose logs jobmanager
    exit 1
fi

echo -e "\n2. Ensure configuration is correct..."
# Check environment variables
KAFKA_BROKER=${KAFKA_BROKER:-kafka-vm:9092}
GCS_BUCKET=${GCS_BUCKET:-rhythmic-events}
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-/opt/flink/secrets/gcp-credentials.json}

# Hiển thị thông tin
echo "KAFKA_BROKER: $KAFKA_BROKER"
echo "GCS_BUCKET: $GCS_BUCKET" 
echo "GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"

# Ensure credentials exist
if [ ! -f "secrets/gcp-credentials.json" ]; then
    echo "ERROR: GCP credentials does not exist at secrets/gcp-credentials.json"
    echo "Please create credentials file before running jobs."
    exit 1
fi

echo -e "\n3. Run main Flink job (stream_all_events.py)..."
docker exec -it jobs-builder python3 /opt/flink/jobs/stream_all_events.py

echo -e "\n4. Check job status..."
docker-compose exec jobmanager flink list

echo -e "\n=== Completed job startup ==="
echo "You can check Flink UI at: http://localhost:8081"
echo "You can check logs by: docker-compose logs -f jobmanager" 