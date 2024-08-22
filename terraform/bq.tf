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

module "bigquery" {
  source       = "terraform-google-modules/bigquery/google"
  version      = "~> 8.1.0"
  dataset_id   = "transcoder_jobs_${var.customer_id}"
  dataset_name = "Transcoder Jobs Stats (${var.customer_id})"
  description  = "Each row of this table represents a Transcoder Job initiated by an upload to the Google Cloud Storage (GCS) bucket or by bulk upload in the Workflow UI."
  project_id   = var.project_id
  location     = var.region
  tables = [
    {
      table_id           = "jobs",
      schema             = file("../analytics/bq-job-stats-schema.json"),
      clustering         = null
      expiration_time    = null
      range_partitioning = null
      time_partitioning  = null
      labels = {
        env = "transcoding"
      },
    },
  ]
  dataset_labels = {
    env = "transcoding"
  }
}

resource "google_bigquery_connection" "cloud_resource_connection" {
  connection_id = "bq-biglake-gcp-resources"
  location      = var.region
  friendly_name = "BigQuery to GCP Resources Connection"
  description   = "Connect with other GCP Resources, such as Google Cloud Storage (GCS) objects."
  cloud_resource {}
}

# This defines a BigQuery object table with manual metadata caching.
resource "google_bigquery_table" "gcs_objects_input" {
  deletion_protection = false
  table_id            = "gcs-objects-input"
  dataset_id          = module.bigquery.bigquery_dataset.dataset_id
  external_data_configuration {
    connection_id = google_bigquery_connection.cloud_resource_connection.name
    autodetect    = false
    # `object_metadata is` required for object tables. For more information, see
    # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table#object_metadata
    object_metadata = "SIMPLE"
    # This defines the source for the prior object table.
    source_uris = [
      "gs://${resource.google_storage_bucket.gcs-input.name}/*",
    ]

    metadata_cache_mode = "MANUAL"
  }

  # This ensures that the connection can access the bucket
  # before Terraform creates a table.
  depends_on = [
    google_project_iam_member.bigquery_sa_objects
  ]
}

resource "google_bigquery_table" "gcs_objects_output" {
  deletion_protection = false
  table_id            = "gcs-objects-output"
  dataset_id          = module.bigquery.bigquery_dataset.dataset_id
  external_data_configuration {
    connection_id = google_bigquery_connection.cloud_resource_connection.name
    autodetect    = false
    # `object_metadata is` required for object tables. For more information, see
    # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table#object_metadata
    object_metadata = "SIMPLE"
    # This defines the source for the prior object table.
    source_uris = [
      "gs://${resource.google_storage_bucket.gcs-output.name}/*",
    ]

    metadata_cache_mode = "MANUAL"
  }

  # This ensures that the connection can access the bucket
  # before Terraform creates a table.
  depends_on = [
    google_project_iam_member.bigquery_sa_objects
  ]
}