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
  dataset_labels = {
    env = "transcoding"
  }
}

# Create a BigQuery Table to house job metadata from the Workflow
resource "google_bigquery_table" "jobs" {
  dataset_id = module.bigquery.bigquery_dataset.dataset_id
  table_id   = "jobs"
  schema     = file("../analytics/bq-job-stats-schema.json")
  labels = {
    env = "transcoding"
  }

  depends_on = [
    module.bigquery
  ]
}

# A BigQuery connection to the rest of the GCP Resources
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

# A view that combines Job statistics, input, and output information
resource "google_bigquery_table" "job-stats-summary" {
  dataset_id = module.bigquery.bigquery_dataset.dataset_id
  table_id   = "job-stats-summary"

  view {
    use_legacy_sql = false
    query = <<EOF
    # Query that combines Job stats information with GCS object metadata and transcoding backend logs.
    SELECT 
      j.JobId,
      j.createdDateTime,
      j.BackendSrv,
      input.URI as input_file_uri,
      input.generation as input_file_generation,
      input.content_type as input_file_content_type,
      input.size as input_file_content_size,
      output.URI as output_file_uri,
      output.generation as outputfile_generation,
      output.content_type as output_file_content_type,
      output.size as output_file_content_size,
    FROM `${module.bigquery.bigquery_dataset.dataset_id}.${google_bigquery_table.jobs.table_id}` AS j
    LEFT JOIN `${module.bigquery.bigquery_dataset.dataset_id}.${google_bigquery_table.gcs_objects_input.table_id}` AS input 
      ON j.FileURI = input.URI
    LEFT JOIN (
      SELECT
        URI,
        SPLIT(URI, "/") AS URI_PARTS,
        generation,
        content_type,
        size
      FROM
        `${module.bigquery.bigquery_dataset.dataset_id}.${google_bigquery_table.gcs_objects_output.table_id}`
      ) AS output
    ON
      output.URI_PARTS[SAFE_OFFSET(2)] = "${resource.google_storage_bucket.gcs-output.name}"
      AND output.URI_PARTS[SAFE_OFFSET(3)] = j.BackendSrv
      AND output.URI_PARTS[SAFE_OFFSET(4)] = j.JobId
    EOF
  }

  depends_on = [
    google_bigquery_table.jobs,
    google_bigquery_table.gcs_objects_input
  ]
}
