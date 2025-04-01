# Flink ETL Jobs

This directory contains Flink jobs for processing streaming data from Kafka and storing it in Google Cloud Storage (GCS).

## Directory Structure

```
flink/
├── config/                 # Flink configuration
├── data/                   # Flink data
│   └── checkpoints/       # Checkpoints
├── jobs/                  # Python Flink jobs
│   ├── schema.py          # Event schema definitions
│   ├── streaming_functions.py  # Streaming processing functions
│   └── stream_all_events.py   # Main job
├── secrets/               # Directory containing credentials
│   └── cred.json         # GCP Service Account key
├── Dockerfile.jobs        # Dockerfile for Flink jobs
├── docker-compose.yml     # Docker Compose configuration
├── run_jobs.sh           # Script to run jobs
├── run_local.sh          # Script to run directly (without Docker)
├── check_setup.sh        # Script to check installation
└── README.md             # This file
```

## Prerequisites

1. **Docker & Docker Compose**: Must be installed on VM
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose
   sudo usermod -aG docker $USER
   ```

2. **GCP Credentials**: Need Service Account JSON file to connect to GCS
   ```bash
   # Create secrets directory
   mkdir -p secrets
   
   # Copy credentials file to secrets directory
   # Name the file cred.json
   cp /path/to/service-account-key.json secrets/cred.json
   ```

3. **Network Connection**: VM must be able to connect to Kafka VM
   ```bash
   # Check connection
   nc -z -v kafka-vm 9092
   ```

## Deployment Steps

1. **Clone repository**:
   ```bash
   git clone <repository_url>
   cd Rhythmic-ETL
   ```

2. **Setup directories and permissions**:
   ```bash
   cd flink
   mkdir -p data/checkpoints secrets
   chmod +x *.sh
   ```

3. **Copy GCP credentials**:
   ```bash
   # Copy credentials file to secrets directory
   cp /path/to/service-account-key.json secrets/cred.json
   ```

4. **Build and start containers**:
   ```bash
   docker-compose up -d --build
   ```

5. **Check installation**:
   ```bash
   ./check_setup.sh
   ```
   
6. **Run Flink jobs**:
   ```bash
   ./run_jobs.sh
   ```

## Troubleshooting

### 1. Kafka Connection Error

If unable to connect to Kafka:

```
WARNING: Cannot connect to Kafka at kafka-vm:9092
```

**Solution**:
- Check if Kafka VM is running: `ssh kafka-vm "docker-compose ps"`
- Check network configuration: `ping kafka-vm`
- Check firewall: `sudo ufw status`

### 2. GCP Credentials Error

If credentials not found:

```
GOOGLE_APPLICATION_CREDENTIALS does not exist
```

**Solution**:
- Copy credentials file to correct location: `cp /path/to/service-account-key.json secrets/cred.json`
- Or set environment variable before running:
  ```bash
  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
  ./run_jobs.sh
  ```

### 3. Python Error

If encountering `No module named...`:

**Solution**:
- Check if Docker container was built correctly: `docker-compose build --no-cache`
- Check libraries: `docker-compose exec jobmanager pip list`

## Monitoring

- **Web UI**: Access http://flink-vm:8081 to view Flink Web UI
- **Logs**: `docker-compose logs jobmanager`
- **Job Status**: `docker-compose exec jobmanager flink list`

## Cleanup

```bash
# Stop containers
docker-compose down

# Delete data (if needed)
rm -rf data/* secrets/*
``` 