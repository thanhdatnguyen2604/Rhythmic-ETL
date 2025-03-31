variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud Zone"
  type        = string
  default     = "us-central1-a"
}

variable "gcs_bucket_name" {
  description = "Name of the GCS bucket"
  type        = string
  default     = "rhythmic-bucket"
}

variable "bq_dataset_name" {
  description = "Name of the BigQuery dataset"
  type        = string
  default     = "rhythmic_dataset"
}

variable "ssh_username" {
  description = "SSH username"
  type        = string
  default     = "rhythmic"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
} 