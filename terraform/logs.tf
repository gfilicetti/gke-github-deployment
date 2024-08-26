# Copyright 2023 Google LLC All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Logs from Google Kubernetes Engine (GKE)
resource "google_logging_project_sink" "bq-log-sink-gke-events" {
  name = "bq-log-sink-gke-events"

  # Export to BigQuery dataset
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${module.bigquery.bigquery_dataset.dataset_id}"

  bigquery_options {
    use_partitioned_tables = true
  }

  # Send all GKE Cluster Event logs to BigQuery
  filter = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"${module.gke.name}\" AND logName=\"projects/${var.project_id}/logs/events\""

  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
}

# Logs from Managed Workflows
resource "google_logging_project_sink" "bq-log-sink-workflow-events" {
  name = "bq-log-sink-workflow-events"

  # Export to BigQuery dataset
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${module.bigquery.bigquery_dataset.dataset_id}"

  bigquery_options {
    use_partitioned_tables = true
  }

  # Send all Workflow Event logs to BigQuery
  filter = "logName=\"projects/${var.project_id}/logs/workflows.googleapis.com%2Fexecutions_system\""

  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
}

# Logs for Batch Jobs Event Logs
resource "google_logging_project_sink" "bq-log-sink-batch-events" {
  name = "bq-log-sink-batch-events"

  # Export to BigQuery dataset
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${module.bigquery.bigquery_dataset.dataset_id}"

  bigquery_options {
    use_partitioned_tables = true
  }

  # Send all Batch API Event logs to BigQuery
  filter = "logName=\"projects/${var.project_id}/logs/batch_task_logs\" OR \"projects/${var.project_id}/logs/batch_agent_logs\""

  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
}