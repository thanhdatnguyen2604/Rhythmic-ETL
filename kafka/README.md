# Kafka and Eventsim Setup

This directory contains configuration and scripts to run Kafka and Eventsim on kafka-vm.

## Directory Structure

```
kafka/
├── config/
│   └── server.properties    # Kafka configuration
├── data/                    # Data directory (created when running prepare_data.sh)
│   ├── zookeeper/          # Zookeeper data
│   ├── kafka/              # Kafka data
│   └── eventsim/           # Eventsim and Million Song Dataset data
├── Dockerfile.eventsim     # Dockerfile for Eventsim
├── docker-compose.yml      # Docker Compose configuration
├── prepare_data.sh         # Data preparation script
├── requirements.txt        # Python dependencies
└── README.md              # This documentation
```

## Deployment Steps on kafka-vm

1. Clone repository and move to kafka directory:
   ```bash
   git clone <repository_url>
   cd kafka
   ```

2. Make scripts executable:
   ```bash
   chmod +x prepare_data.sh
   ```

3. Run data preparation script:
   ```bash
   ./prepare_data.sh
   ```
   This script will:
   - Create necessary directory structure
   - Download Million Song Dataset (approximately 1.8GB) from official source
   - Extract dataset to data/eventsim/MillionSongSubset directory
   - Create configuration files for Kafka and Eventsim
   - Set access permissions for directories

4. Check downloaded data:
   ```bash
   # Check dataset size
   du -sh data/eventsim/MillionSongSubset
   
   # Check number of .h5 files
   find data/eventsim/MillionSongSubset -name "*.h5" | wc -l
   ```

5. Build and start containers:
   ```bash
   docker-compose up -d --build
   ```

6. Check status:
   ```bash
   docker-compose ps
   ```

7. View logs:
   ```bash
   # View logs for all services
   docker-compose logs

   # View logs for specific service
   docker-compose logs kafka
   docker-compose logs eventsim
   ```

## Operational Checks

1. Check Kafka topics:
   ```bash
   docker-compose exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092
   ```

2. View data from Eventsim:
   ```bash
   docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic listen_events --from-beginning --max-messages 5
   ```

## Stop and Cleanup

1. Stop containers:
   ```bash
   docker-compose down
   ```

2. Delete data (if needed):
   ```bash
   rm -rf data/*
   ```

## Important Notes

- **Data**: Million Song Dataset will be downloaded when running `prepare_data.sh` on kafka-vm
- **Storage**: Requires at least 4GB free space (1.8GB for dataset + 2GB for Kafka data)
- **RAM**: Containers need at least 2GB RAM to operate properly
- **Time**: Dataset download and extraction may take 5-10 minutes depending on network speed 