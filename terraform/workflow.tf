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
data "local_file" "input_template" {
  filename = "../workflows/workflow.yaml"
}

resource "google_workflows_workflow" "transcoding_workflow" {
  name        = "workflow-${var.customer_id}-gcs-transcoding"
  region      = var.region
  description = "Upon upload of a new video file to GCS, this workload picks the most appropriate backend transcoding service to execute the job."
  labels = {
    env = "transcoding"
  }

  user_env_vars = {
    DOCKER_IMAGE_URI     = "${var.region}-docker.pkg.dev/${var.project_id}/repo-batch-jobs/ffmpeg:latest"
    GCS_DESTINATION      = "gcs-${var.project_id}-${var.customer_id}-test-output"
    MACHINE_CPU_MILLI    = "16000"
    MACHINE_MEMORY_MIB   = "65536"
    MACHINE_TYPE         = "c2-standard-16"
    VPC_NETWORK_FULLNAME = module.vpc.network_name
    GKE_CLUSTER_NAME     = "gke-${var.customer_id}-test"
    GKE_NAMESPACE        = "${var.job_namespace}"
    VPC_NETWORK_FULLNAME = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/networks/${module.vpc.network_name}"
    VPC_SUBNETWORK_FULLNAME = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/us-central1/subnetworks/sn-${var.customer_id}-${var.region}"
  }

  source_contents = data.local_file.input_template.content
}

resource "google_eventarc_trigger" "primary" {
  name            = "trigger-${var.customer_id}-gcs-transcoding"
  location        = var.region
  service_account = data.google_compute_default_service_account.default.email
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = "gcs-${var.project_id}-${var.customer_id}-test-input"
  }
  destination {
    workflow = "projects/${var.project_id}/locations/${var.region}/workflows/workflow-${var.customer_id}-gcs-transcoding"
  }
}