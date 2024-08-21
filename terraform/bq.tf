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
