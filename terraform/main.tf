provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create GCS Bucket for dataset
resource "google_storage_bucket" "rhythmic_bucket" {
  name     = var.gcs_bucket_name
  location = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

# Create VM for Kafka 
resource "google_compute_instance" "kafka_vm" {
  name         = "kafka-vm"
  machine_type = "e2-medium"
  tags         = ["kafka"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
  }

  scheduling {
    preemptible = true
    automatic_restart = false
  }
}

# Create VM for Flink
resource "google_compute_instance" "flink_vm" {
  name         = "flink-vm"
  machine_type = "e2-standard-2"  # 2 vCPU, 8GB RAM
  tags         = ["flink"]    

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 50  
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
  }
  
  scheduling {
    preemptible = true
    automatic_restart = false
  }
}

# Create VM for Airflow
resource "google_compute_instance" "airflow_vm" {
  name         = "airflow-vm"
  machine_type = "e2-micro"
  tags         = ["airflow"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
  }
}

# Create Dataset for BigQuery
resource "google_bigquery_dataset" "rhythmic_dataset" {
  dataset_id                  = var.bq_dataset_name
  friendly_name               = "Rhythmic Dataset"
  description                 = "Dataset for music streaming data"
  location                    = var.region
  delete_contents_on_destroy  = true
} 