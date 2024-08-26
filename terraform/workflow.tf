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
data "local_file" "upload_input_template" {
  filename = "../workflows/upload-event-workflow.yaml"
}
data "local_file" "bulk_input_template" {
  filename = "../workflows/bulk-workflow.yaml"
}

resource "google_workflows_workflow" "event_transcoding_workflow" {
  name        = "upload-event-gcs-${var.customer_id}-transcoding"
  region      = var.region
  description = "Upon upload of a new video file to GCS, this workload picks the most appropriate backend transcoding service to execute the job."
  labels = {
    env = "transcoding"
  }

  user_env_vars = {
    DOCKER_IMAGE_URI        = "${var.region}-docker.pkg.dev/${local.project.id}/repo-batch-jobs/ffmpeg:latest"
    GCS_DESTINATION         = "${resource.google_storage_bucket.gcs-output.name}"
    MACHINE_CPU_MILLI       = "16000"
    MACHINE_MEMORY_MIB      = "65536"
    MACHINE_TYPE            = "c2-standard-16"
    GKE_CLUSTER_NAME        = "${module.gke.name}"
    GKE_NAMESPACE           = "${var.job_namespace}"
    VPC_NETWORK_FULLNAME    = "${module.vpc.network_self_link}"
    VPC_SUBNETWORK_FULLNAME = "https://www.googleapis.com/compute/v1/projects/${local.project.id}/regions/${var.region}/subnetworks/sn-${var.customer_id}-${var.region}"
    BQ_JOBS_STATS_DATASET   = "transcoder_jobs_${var.customer_id}"
    BQ_JOBS_STATS_TABLE     = "jobs"
  }

  source_contents = data.local_file.upload_input_template.content
}

resource "google_workflows_workflow" "bulk_transcoding_workflow" {
  name        = "bulk-${var.customer_id}-transcoding"
  region      = var.region
  description = "Establish a bulk transcoding request and kick off the backend jobs."
  labels = {
    env = "transcoding"
  }

  user_env_vars = {
    EVENT_WORKFLOW_NAME = resource.google_workflows_workflow.event_transcoding_workflow.name
  }

  source_contents = data.local_file.bulk_input_template.content
}

################################
## EVENTARC PROVISIONING HACK ##
################################

resource "google_eventarc_trigger" "primary" {
  name            = "trigger-${var.customer_id}-gcs-transcoding"
  location        = var.region
  service_account = google_service_account.eventarc.email
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = resource.google_storage_bucket.gcs-input.name
  }
  destination {
    workflow = "projects/${local.project.id}/locations/${var.region}/workflows/${resource.google_workflows_workflow.event_transcoding_workflow.name}"
  }

  depends_on = [
    time_sleep.wait_for_service_agent_readiness,
    module.member_roles_default_compute,
    module.member_roles_gcs_service_account
  ]
}