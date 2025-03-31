provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Tạo GCS Bucket cho dữ liệu
resource "google_storage_bucket" "rhythmic_bucket" {
  name     = var.gcs_bucket_name
  location = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

# Tạo VM cho Kafka 
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

# Tạo VM cho Flink (thay vì Spark)
resource "google_compute_instance" "flink_vm" {
  name         = "flink-vm"
  machine_type = "e2-medium"  # Nâng lên từ e2-micro để đủ tài nguyên
  tags         = ["flink"]    # Tag đúng với công nghệ sử dụng

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 50  # Nâng lên 50GB theo yêu cầu
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

# Tạo VM cho Airflow
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

# Tạo Dataset trong BigQuery
resource "google_bigquery_dataset" "rhythmic_dataset" {
  dataset_id                  = var.bq_dataset_name
  friendly_name               = "Rhythmic Dataset"
  description                 = "Dataset for music streaming data"
  location                    = var.region
  delete_contents_on_destroy  = true
} 