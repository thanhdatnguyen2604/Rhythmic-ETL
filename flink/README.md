# Flink ETL Jobs

This directory contains the Flink streaming ETL configurations and jobs for the Rhythmic-ETL project.

## Architecture Overview

The Flink component is responsible for:
1. Reading events from Kafka
2. Processing and transforming the data
3. Storing results in Google Cloud Storage (GCS)

## Directory Structure

- `jobs/` - Flink job Python scripts
  - `stream_all_events.py` - Main job that processes all events
  - `schema.py` - Event schema definitions
  - `streaming_functions.py` - Functions for processing events
- `config/` - Configuration files
- `secrets/` - GCP credentials (not included in repo)
- `checkpoints/` - Checkpoint storage for Flink jobs
- `Dockerfile.jobs` - Dockerfile for Flink jobs
- `docker-compose.yml` - Docker compose configuration
- `run_jobs.sh` - Script to run Flink jobs
- `run_local.sh` - Script to run jobs locally for testing
- `check_setup.sh` - Script to check environment setup

## Quick Start

1. Create the secrets directory and add GCP credentials:
   ```bash
   mkdir -p secrets
   # Copy your GCP credentials JSON to secrets/cred.json
   ```

2. Run the setup check:
   ```bash
   chmod +x check_setup.sh
   ./check_setup.sh
   ```

3. Start Flink services:
   ```bash
   docker-compose up -d
   ```

4. Run the Flink jobs:
   ```bash
   chmod +x run_jobs.sh
   ./run_jobs.sh
   ```

## Detailed Job Documentation

### Main Job: `stream_all_events.py`

This job handles streaming data from Kafka topics and writing to GCS. It processes:

1. **Listen Events** (`listen_events` topic)
   - User song listening data
   - Schema defined in `schema.py`
   - Processed by `process_listen_events()` in `streaming_functions.py`
   - Written to GCS in `/listen_events/year=/month=/day=/hour=` partitions

2. **Page View Events** (`page_view_events` topic)
   - User interface interaction data
   - Schema defined in `schema.py`
   - Processed by `process_page_view_events()` in `streaming_functions.py`
   - Written to GCS in `/page_view_events/year=/month=/day=/hour=` partitions

3. **Auth Events** (`auth_events` topic)
   - User authentication data
   - Schema defined in `schema.py`
   - Processed by `process_auth_events()` in `streaming_functions.py`
   - Written to GCS in `/auth_events/year=/month=/day=/hour=` partitions

### Job Configuration

Key environment variables:

- `KAFKA_BROKER`: Kafka broker address (default: `kafka-vm:9092`)
- `GCS_BUCKET`: GCS bucket name (default: `rhythmic-bucket`)
- `CHECKPOINT_DIR`: Flink checkpoint directory (default: `file:///opt/flink/checkpoints`)
- `CHECKPOINT_INTERVAL`: Checkpoint interval in ms (default: `60000`)
- `PARALLELISM`: Default parallelism (default: `1`)

### Performance Settings

Flink is configured with optimized settings for performance:

1. **Checkpointing**:
   - Mode: EXACTLY_ONCE
   - Interval: 60 seconds
   - Timeout: 30 seconds
   - Max concurrent checkpoints: 1

2. **JobManager**:
   - Memory: 1024MB

3. **TaskManager**:
   - Memory: 1536MB
   - Managed memory: 512MB
   - Task slots: 2

## Debugging and Troubleshooting

### Common Issues and Solutions

#### 1. Job Fails to Start

**Symptoms**: Job submission fails, errors in JobManager logs

**Troubleshooting Steps**:
1. Check JobManager logs:
   ```bash
   docker-compose logs jobmanager
   ```
2. Verify file permissions:
   ```bash
   ls -la ./jobs/
   ls -la ./secrets/
   ```
3. Verify imports and dependencies in job script

**Solutions**:
- Set correct permissions: `chmod -R 644 ./jobs/*.py`
- Ensure `cred.json` exists in secrets directory
- Update dependencies in `Dockerfile.jobs`

#### 2. Kafka Connection Issues

**Symptoms**: Job runs but no data is processed, connection errors in logs

**Troubleshooting Steps**:
1. Verify Kafka is running:
   ```bash
   telnet kafka-vm 9092
   ```
2. Check network connectivity:
   ```bash
   ping kafka-vm
   ```
3. Check Kafka topic existence:
   ```bash
   docker-compose exec jobmanager bash -c "curl -s kafka-vm:9092/topics"
   ```

**Solutions**:
- Update `KAFKA_BROKER` environment variable to correct address
- Ensure Kafka topics exist
- Check network configuration between VMs

#### 3. GCS Write Failures

**Symptoms**: Jobs run but data is not appearing in GCS

**Troubleshooting Steps**:
1. Check credentials:
   ```bash
   cat secrets/cred.json | jq .
   ```
2. Verify GCS bucket existence and permissions:
   ```bash
   gsutil ls -la gs://rhythmic-bucket/
   ```
3. Check error logs:
   ```bash
   docker-compose logs jobs-builder
   ```

**Solutions**:
- Ensure credentials have proper permissions (Storage Admin role)
- Create GCS bucket if it doesn't exist:
   ```bash
   gsutil mb -l us-central1 gs://rhythmic-bucket
   ```
- Set `GOOGLE_APPLICATION_CREDENTIALS` correctly

#### 4. Job Performance Issues

**Symptoms**: High processing latency, backpressure in Flink UI

**Troubleshooting Steps**:
1. Check backpressure in Flink UI (http://flink-vm:8081)
2. Monitor resource usage:
   ```bash
   docker stats
   ```
3. Check checkpoint metrics in Flink UI

**Solutions**:
- Increase parallelism in task or job configuration
- Increase memory allocation in `docker-compose.yml`
- Tune checkpoint interval based on load

### Live Debugging Tips

1. **Access Flink UI**:
   The Flink UI is available at: http://flink-vm:8081
   
   Use it to:
   - Monitor job execution
   - View task metrics
   - Check backpressure
   - View exceptions

2. **Monitor Job Logs**:
   ```bash
   # JobManager logs
   docker-compose logs -f jobmanager
   
   # TaskManager logs
   docker-compose logs -f taskmanager
   ```

3. **Testing with Sample Data**:
   Use `run_local.sh` to test jobs with sample data before deployment

4. **Rescue a Failed Job**:
   If a job fails and you need to retain its state:
   ```bash
   # 1. Get job ID
   docker-compose exec jobmanager ./bin/flink list
   
   # 2. Cancel job with savepoint
   docker-compose exec jobmanager ./bin/flink cancel --withSavepoint <job-id>
   
   # 3. Restart from savepoint
   docker-compose exec jobmanager ./bin/flink run -s <savepoint-path> /opt/flink/jobs/stream_all_events.py
   ```

## Testing

To run tests on the jobs:

```bash
# Run local tests
./run_local.sh

# Check test output
cat test_output.json
```

## Recommendations

1. **Resource Allocation**:
   - For production, increase TaskManager memory to at least 4GB
   - Increase parallelism based on VM size and load

2. **Checkpoint Configuration**:
   - Adjust checkpoint interval based on data volume and latency requirements
   - Consider using RocksDB for state backend on larger datasets

3. **Monitoring**:
   - Set up alerting based on Flink metrics
   - Monitor GCS storage growth and implement cleanup policies

4. **Troubleshooting Tools**:
   ```bash
   # Check Flink job status
   docker-compose exec jobmanager ./bin/flink list
   
   # View TaskManager details
   docker-compose exec jobmanager ./bin/flink list -t
   
   # Detailed metrics
   docker-compose exec jobmanager ./bin/flink list -m
   ``` 