# GCP Resource Optimization

This document outlines the optimization strategies for GCP resources in the Rhythmic-ETL project.

## VM Instance Types

### 1. Kafka VM (e2-small)

**Specifications**:
- 2 vCPU (shared)
- 2GB RAM
- 10GB SSD

**Optimization Strategies**:
- Use preemptible instances for cost savings
- Configure Kafka for low memory usage
- Enable auto-scaling based on CPU usage

**Cost Analysis**:
- Regular: ~$12.41/month
- Preemptible: ~$3.72/month
- Estimated daily cost: $0.12 (preemptible)

### 2. Flink VM (e2-medium)

**Specifications**:
- 2 vCPU (shared)
- 4GB RAM
- 50GB SSD

**Optimization Strategies**:
- Use preemptible instances
- Configure Flink for optimal memory usage
- Enable checkpointing to SSD

**Cost Analysis**:
- Regular: ~$24.82/month + $5 (disk)
- Preemptible: ~$7.45/month + $5 (disk)
- Estimated daily cost: $0.41 (preemptible)

### 3. Airflow VM (e2-micro)

**Specifications**:
- 2 vCPU (shared)
- 1GB RAM
- 10GB SSD

**Optimization Strategies**:
- Use preemptible instances
- Configure LocalExecutor for minimal resource usage
- Limit concurrent DAG runs

**Cost Analysis**:
- Regular: ~$6.20/month
- Preemptible: ~$1.86/month
- Estimated daily cost: $0.06 (preemptible)

## Storage Optimization

### 1. GCS Bucket

**Configuration**:
```terraform
resource "google_storage_bucket" "data_bucket" {
  name     = "${var.project_id}-data"
  location = var.region
  
  lifecycle_rule {
    condition {
      age = 30  # Delete data after 30 days
    }
    action {
      type = "Delete"
    }
  }
  
  uniform_bucket_level_access = true
}
```

**Optimization Strategies**:
- Use lifecycle rules to delete old data
- Implement data partitioning
- Enable compression

**Cost Analysis**:
- Storage: $0.02/GB/month
- Network egress: $0.12/GB
- Estimated monthly cost: ~$5-10

### 2. BigQuery Dataset

**Configuration**:
```terraform
resource "google_bigquery_dataset" "analytics" {
  dataset_id = "rhythmic_analytics"
  location   = var.region
  
  default_table_expiration_ms = 2592000000  # 30 days
}
```

**Optimization Strategies**:
- Partition tables by date
- Cluster by frequently queried columns
- Use materialized views for common queries

**Cost Analysis**:
- Storage: $0.02/GB/month
- Query: $5/TB
- Estimated monthly cost: ~$10-20

## Network Optimization

### 1. VPC Configuration

```terraform
resource "google_compute_network" "vpc" {
  name = "rhythmic-network"
  
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "rhythmic-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.0.0.0/24"
}
```

**Optimization Strategies**:
- Use internal IPs for VM communication
- Implement firewall rules
- Enable VPC flow logs

### 2. Load Balancing

**Configuration**:
```terraform
resource "google_compute_global_address" "default" {
  name = "rhythmic-ip"
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "rhythmic-lb"
  ip_protocol          = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range           = "80"
  target               = google_compute_target_http_proxy.default.id
  ip_address           = google_compute_global_address.default.id
}
```

**Optimization Strategies**:
- Use HTTP(S) load balancing
- Enable SSL/TLS
- Configure health checks

## Cost Management

### 1. Budget Alerts

```terraform
resource "google_billing_budget" "budget" {
  billing_account = var.billing_account_id
  display_name    = "Rhythmic Budget"
  
  budget_filter {
    projects = ["projects/${var.project_id}"]
  }
  
  amount {
    specified_amount {
      currency_code = "USD"
      units        = "100"
    }
  }
  
  threshold_rules {
    threshold_percent = 0.5
  }
}
```

### 2. Resource Scheduling

```bash
# Start VMs
gcloud compute instances start kafka-vm flink-vm airflow-vm --zone=us-central1-a

# Stop VMs
gcloud compute instances stop kafka-vm flink-vm airflow-vm --zone=us-central1-a
```

## Monitoring and Logging

### 1. Cloud Monitoring

```terraform
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage"
  combiner     = "OR"
  conditions {
    display_name = "CPU Usage > 80%"
    condition_threshold {
      filter     = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
    }
  }
}
```

### 2. Cloud Logging

```terraform
resource "google_logging_metric" "error_rate" {
  name        = "error_rate"
  filter      = "severity=ERROR"
  metric_kind = "DELTA"
  value_type  = "INT64"
}
```

## Best Practices

1. **Resource Management**:
   - Use preemptible instances when possible
   - Implement auto-scaling
   - Regular resource cleanup

2. **Cost Optimization**:
   - Monitor usage patterns
   - Set up budget alerts
   - Use committed use discounts

3. **Performance**:
   - Optimize storage patterns
   - Use appropriate instance types
   - Implement caching strategies

4. **Security**:
   - Use service accounts
   - Implement least privilege
   - Enable audit logging