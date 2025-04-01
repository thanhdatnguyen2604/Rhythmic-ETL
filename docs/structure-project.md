# Project Structure

This document describes the structure of the Rhythmic-ETL project.

## Root Directory Structure

```
Rhythmic-ETL/
├── airflow/              # Airflow configuration and DAGs
├── docs/                 # Project documentation
├── flink/               # Flink jobs and configuration
├── kafka/               # Kafka and Eventsim setup
├── terraform/           # Infrastructure as Code
└── README.md            # Project overview
```

## Component Details

### 1. Airflow (`airflow/`)

```
airflow/
├── dags/                # Airflow DAGs
├── logs/                # Airflow logs
├── plugins/             # Custom Airflow plugins
├── config/              # Airflow configuration
├── secrets/             # GCP credentials
└── docker-compose.yml   # Airflow services
```

### 2. Flink (`flink/`)

```
flink/
├── jobs/               # Flink Python jobs
│   ├── schema.py       # Event schemas
│   ├── streaming_functions.py
│   └── stream_all_events.py
├── config/             # Flink configuration
├── data/               # Flink data
│   └── checkpoints/    # Checkpoint data
├── secrets/            # GCP credentials
├── Dockerfile.jobs     # Flink job container
├── docker-compose.yml  # Flink services
└── run_jobs.sh         # Job execution script
```

### 3. Kafka (`kafka/`)

```
kafka/
├── config/             # Kafka configuration
├── data/               # Kafka and Eventsim data
│   ├── zookeeper/      # Zookeeper data
│   ├── kafka/          # Kafka data
│   └── eventsim/       # Million Song Dataset
├── Dockerfile.eventsim # Eventsim container
├── docker-compose.yml  # Kafka services
└── prepare_data.sh     # Data preparation script
```

### 4. Terraform (`terraform/`)

```
terraform/
├── main.tf             # Main Terraform configuration
├── variables.tf        # Input variables
├── outputs.tf          # Output values
└── .terraform/         # Terraform state
```

### 5. Documentation (`docs/`)

```
docs/
├── ETL.md              # ETL process documentation
├── million_song_dataset.md
├── structure-project.md
├── gcp_optimization.md
├── airflow_optimization.md
├── flink_optimization.md
└── kafka_optimization.md
```

## Key Files

### Configuration Files

1. **Docker Compose Files**:
   - `kafka/docker-compose.yml`: Kafka and Zookeeper services
   - `flink/docker-compose.yml`: Flink job manager and task manager
   - `airflow/docker-compose.yml`: Airflow webserver and scheduler

2. **Dockerfiles**:
   - `kafka/Dockerfile.eventsim`: Eventsim container
   - `flink/Dockerfile.jobs`: Flink jobs container

3. **Terraform Files**:
   - `terraform/main.tf`: GCP infrastructure
   - `terraform/variables.tf`: Input variables
   - `terraform/outputs.tf`: Output values

### Scripts

1. **Data Preparation**:
   - `kafka/prepare_data.sh`: Downloads and prepares Million Song Dataset

2. **Job Execution**:
   - `flink/run_jobs.sh`: Runs Flink streaming jobs
   - `flink/check_setup.sh`: Validates Flink setup

### Documentation

1. **Process Documentation**:
   - `docs/ETL.md`: ETL process details
   - `docs/million_song_dataset.md`: Dataset information

2. **Optimization Guides**:
   - `docs/gcp_optimization.md`: GCP resource optimization
   - `docs/airflow_optimization.md`: Airflow performance tuning
   - `docs/flink_optimization.md`: Flink job optimization
   - `docs/kafka_optimization.md`: Kafka performance tuning

## Data Flow

1. **Data Ingestion**:
   - Eventsim generates events from Million Song Dataset
   - Events are sent to Kafka topics

2. **Stream Processing**:
   - Flink jobs process events from Kafka
   - Processed data is stored in GCS

3. **Batch Processing**:
   - Airflow DAGs schedule batch jobs
   - Results are stored in BigQuery

## Security Considerations

1. **Credentials**:
   - GCP credentials stored in `*/secrets/cred.json`
   - Not committed to version control

2. **Network Security**:
   - Internal communication between services
   - External access limited to necessary ports

3. **Data Access**:
   - Service accounts with minimal required permissions
   - Data encryption at rest and in transit

## Development Guidelines

1. **Code Organization**:
   - Follow component-specific directory structure
   - Keep configuration separate from code
   - Document all major components

2. **Version Control**:
   - Use meaningful commit messages
   - Keep sensitive data out of version control
   - Tag releases appropriately

3. **Testing**:
   - Test components individually
   - Validate data flow end-to-end
   - Monitor system performance
