# Makefile for Rhythmic-ETL project

# Variables
PYTHON = python3
PIP = pip3
TERRAFORM = terraform
VENV = venv
VENV_BIN = $(VENV)/bin

# Phần Setup
.PHONY: setup
setup: venv terraform-init

venv:
	$(PYTHON) -m venv $(VENV)
	$(VENV_BIN)/$(PIP) install --upgrade pip
	$(VENV_BIN)/$(PIP) install -r requirements.txt

# GCP và Terraform
.PHONY: terraform-init terraform-plan terraform-apply terraform-destroy
terraform-init:
	cd terraform && $(TERRAFORM) init

terraform-plan:
	cd terraform && $(TERRAFORM) plan

terraform-apply:
	cd terraform && $(TERRAFORM) apply

terraform-destroy:
	cd terraform && $(TERRAFORM) destroy

# Quản lý VM
.PHONY: start-vms stop-vms
start-vms:
	./scripts/vm_control.sh $(GCP_PROJECT_ID) $(GCP_ZONE) start

stop-vms:
	./scripts/vm_control.sh $(GCP_PROJECT_ID) $(GCP_ZONE) stop

# Kafka commands
.PHONY: kafka-start kafka-stop kafka-status
kafka-start:
	ssh kafka-vm "cd ~/Rhythmic-ETL/kafka && docker-compose up -d"

kafka-stop:
	ssh kafka-vm "cd ~/Rhythmic-ETL/kafka && docker-compose down"

kafka-status:
	ssh kafka-vm "cd ~/Rhythmic-ETL/kafka && docker-compose ps"

# Flink commands
.PHONY: flink-start flink-stop flink-status flink-run-job
flink-start:
	ssh flink-vm "cd ~/Rhythmic-ETL/flink && docker-compose up -d"

flink-stop:
	ssh flink-vm "cd ~/Rhythmic-ETL/flink && docker-compose down"

flink-run-job:
	ssh flink-vm "cd ~/Rhythmic-ETL/flink_jobs && flink run -py stream_all_events.py"

# Airflow commands
.PHONY: airflow-start airflow-stop
airflow-start:
	ssh airflow-vm "cd ~/Rhythmic-ETL/airflow && docker-compose up -d"

airflow-stop:
	ssh airflow-vm "cd ~/Rhythmic-ETL/airflow && docker-compose down"

# dbt commands
.PHONY: dbt-run dbt-test
dbt-run:
	ssh airflow-vm "cd ~/Rhythmic-ETL/dbt && dbt run"

dbt-test:
	ssh airflow-vm "cd ~/Rhythmic-ETL/dbt && dbt test"

# Cleanup
.PHONY: clean
clean:
	rm -rf $(VENV)
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
