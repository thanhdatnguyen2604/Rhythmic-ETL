# Kafka and Million Song Dataset Producer Setup

This directory contains configuration and scripts to set up Kafka and a producer that uses the Million Song Dataset to generate music streaming events.

## Directory Structure

- `config/` - Configuration files
- `data/` - Data directory for Kafka, Zookeeper, and Million Song Dataset
- `docker-compose.yml` - Docker Compose file for Kafka and Zookeeper
- `prepare_data.sh` - Script to prepare the directory structure and download the dataset
- `simple_producer.py` - Python script that reads HDF5 files and sends events to Kafka

## Deployment Steps on kafka-vm

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Rhythmic-ETL/kafka
   ```

2. **Prepare the environment**
   ```bash
   chmod +x prepare_data.sh
   ./prepare_data.sh
   ```
   - This script will create necessary directories and configuration files
   - It will download and extract the Million Song Dataset (approximately 10GB)
   - This may take 15-30 minutes depending on your connection

3. **Start Kafka and Zookeeper**
   ```bash
   docker-compose up -d
   ```

4. **Check the status**
   ```bash
   docker-compose ps
   ```

5. **View logs**
   ```bash
   docker-compose logs -f
   ```

## Running the Producer

The producer reads song data from the Million Song Dataset and generates music listening and page view events.

1. **Install required Python packages**
   ```bash
   pip install kafka-python h5py
   ```

2. **Run the producer**
   ```bash
   python simple_producer.py
   ```

3. **Stop the producer**
   Press `Ctrl+C` to stop the producer.

## Operational Checks

### Verify Kafka Topics
```bash
docker-compose exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

### Check Messages in a Topic
```bash
docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic listen_events --from-beginning
```

## Stop and Cleanup

```bash
docker-compose down
```

## Important Notes

1. **Requirements**
   - Docker and Docker Compose
   - Python 3.6+
   - At least 2GB of RAM
   - At least 10GB of disk space for the Million Song Dataset

2. **Network Configuration**
   - The Kafka broker is available at `localhost:9092` from the host
   - From other containers/VMs, use `kafka-vm:9092` (replace with actual hostname)

3. **Connection from flink-vm**
   - Make sure network connectivity exists between flink-vm and kafka-vm
   - Kafka port 9092 should be accessible from flink-vm
   - Update your Flink jobs to use the correct Kafka broker address: `kafka-vm:9092`

4. **About the Million Song Dataset**
   - This project uses the Million Song Dataset to generate realistic music data
   - The dataset contains metadata for one million songs in HDF5 format
   - Documentation: http://millionsongdataset.com/ 