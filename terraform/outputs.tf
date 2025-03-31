output "kafka_vm_external_ip" {
  value = google_compute_instance.kafka_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP của Kafka VM"
}

output "flink_vm_external_ip" {
  value = google_compute_instance.flink_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP của Flink VM"
}

output "airflow_vm_external_ip" {
  value = google_compute_instance.airflow_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP của Airflow VM"
}

output "gcs_bucket_name" {
  value = google_storage_bucket.rhythmic_bucket.name
  description = "Tên của GCS bucket"
}

output "bigquery_dataset_id" {
  value = google_bigquery_dataset.rhythmic_dataset.dataset_id
  description = "ID của BigQuery dataset"
}