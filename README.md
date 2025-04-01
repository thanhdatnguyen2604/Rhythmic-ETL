# Rhythmic-ETL: Streaming and Batch Data Processing

Rhythmic-ETL is an End-to-End Data Engineering project using Kafka, Flink, and Airflow to process streaming and batch data from a music streaming application.

## System Architecture

The project is deployed on 3 separate VMs on GCP:

1. **kafka-vm**: Contains Kafka Cluster and Eventsim application to simulate streaming data.
2. **flink-vm**: Contains Flink to process streaming data and store it in GCS.
3. **airflow-vm**: Contains Airflow to orchestrate ETL and Analytics tasks.

![System Architecture](docs/images/architecture.png)

## Main Components

- **Terraform**: Automates infrastructure deployment on GCP
- **Kafka & Eventsim**: Generate and process streaming events
- **Flink**: Process streaming data in real-time
- **GCS**: Store analytics data
- **Airflow**: Orchestrate ETL processes

## Quick Start

1. **Setup Terraform**:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

2. **Setup Kafka**:
   ```bash
   # SSH into kafka-vm
   cd kafka
   chmod +x prepare_data.sh
   ./prepare_data.sh
   docker-compose up -d
   ```

3. **Setup Flink**:
   ```bash
   # SSH into flink-vm
   cd flink
   mkdir -p secrets
   # Copy GCP credentials to secrets/cred.json
   chmod +x *.sh
   ./check_setup.sh
   docker-compose up -d
   ./run_jobs.sh
   ```

4. **Setup Airflow**:
   ```bash
   # SSH into airflow-vm
   cd airflow
   mkdir -p dags logs plugins config secrets
   # Copy GCP credentials to secrets/cred.json
   docker-compose up airflow-init
   docker-compose up -d
   ```

## Detailed Documentation

- [ETL Guide](docs/ETL.md)
- [Kafka & Eventsim](kafka/README.md)
- [Flink Jobs](flink/README.md)
- [Airflow](airflow/README.md)
- [Million Song Dataset](docs/million_song_dataset.md)
- [GCP Optimization](docs/gcp_optimization.md)

## Analysis Examples

1. **Top 10 Most Played Songs**:
   ```sql
   SELECT song, artist, COUNT(*) as plays
   FROM listen_events
   GROUP BY song, artist
   ORDER BY plays DESC
   LIMIT 10
   ```

2. **Hourly Interaction Levels**:
   ```sql
   SELECT EXTRACT(HOUR FROM datetime) as hour, COUNT(*) as interactions
   FROM page_view_events
   GROUP BY hour
   ORDER BY hour
   ```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.