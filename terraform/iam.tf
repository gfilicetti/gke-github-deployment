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

# Create a service account for Eventarc Trigger
resource "google_service_account" "eventarc" {
  account_id   = "eventarc-trigger-sa"
  display_name = "TF - Eventarc Trigger SA"
  project      = local.project.id
}


# Create a service account for GKE cluster
resource "google_service_account" "sa_gke_cluster" {
  account_id   = "sa-${var.customer_id}-gke-cluster"
  display_name = "TF - GKE cluster SA"
  project      = local.project.id
}

resource "google_service_account_iam_binding" "sa_gke_cluster_wi_binding" {
  service_account_id = google_service_account.sa_gke_cluster.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${local.project.id}.svc.id.goog[${var.job_namespace}/k8s-sa-cluster]",
  ]
  depends_on = [
    module.gke
  ]
}

# Add roles to the created GKE cluster service account
module "member_roles_gke_cluster" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = google_service_account.sa_gke_cluster.email
  prefix                  = "serviceAccount"
  project_id              = local.project.id
  project_roles = [
    "roles/artifactregistry.reader",
    "roles/cloudtrace.agent",
    "roles/container.admin",
    "roles/container.clusterAdmin",
    "roles/container.developer",
    "roles/container.nodeServiceAgent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.admin",
    "roles/storage.objectUser",
  ]

  depends_on = [google_project_service_identity.service_identity]
}

# Add roles to the created EventArc service account
module "member_roles_eventarc_trigger" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = google_service_account.eventarc.email
  prefix                  = "serviceAccount"
  project_id              = local.project.id
  project_roles = [
    "roles/eventarc.eventReceiver",
    "roles/workflows.invoker"
  ]

  depends_on = [google_project_service_identity.service_identity]
}

# Add roles to the default Cloud Build service account
module "member_roles_cloudbuild" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = local.service_accounts_default.cloudbuild
  prefix                  = "serviceAccount"
  project_id              = local.project.id
  project_roles = [
    "roles/artifactregistry.reader",
    "roles/artifactregistry.repoAdmin",
    "roles/artifactregistry.serviceAgent",
    "roles/batch.agentReporter",
    "roles/batch.jobsEditor",
    "roles/batch.serviceAgent",
    "roles/cloudbuild.builds.builder",
    "roles/cloudbuild.connectionAdmin",
    "roles/container.developer",
    "roles/eventarc.serviceAgent",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/storage.objectAdmin",
    "roles/storage.objectUser",
    "roles/storage.objectViewer",
    "roles/transcoder.admin",
    "roles/transcoder.serviceAgent",
    "roles/workflows.invoker",
    "roles/workflows.serviceAgent",
  ]

  depends_on = [google_project_service_identity.service_identity]
}

# Add roles to the default Compute service account
module "member_roles_default_compute" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = local.service_accounts_default.compute
  prefix                  = "serviceAccount"
  project_id              = local.project.id
  project_roles = [
    "roles/iam.serviceAccountUser",
    # Artifact Registry
    "roles/artifactregistry.writer",
    "roles/artifactregistry.serviceAgent",
    "roles/artifactregistry.reader",
    # Batch API
    "roles/batch.jobsEditor",
    "roles/batch.serviceAgent",
    "roles/batch.agentReporter",
    # EventArc
    "roles/eventarc.serviceAgent",
    "roles/eventarc.eventReceiver",
    "roles/pubsub.publisher",
    # GKE
    "roles/container.developer",
    # Storage
    "roles/storage.admin",
    "roles/storage.objectUser",
    # Transcoder API
    "roles/transcoder.admin",
    "roles/transcoder.serviceAgent",
    # Workflows
    "roles/logging.logWriter",
    "roles/workflows.invoker",
    "roles/workflows.serviceAgent",
    # BigQuery
    "roles/bigquery.dataEditor",
    "roles/bigquery.user",
  ]

  depends_on = [google_project_service_identity.service_identity]
}

# Add roles to the default Google Cloud Storage (GCS) service account
module "member_roles_gcs_service_account" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = local.service_accounts_default.storage
  prefix                  = "serviceAccount"
  project_id              = local.project.id
  project_roles = [
    # EventArc
    "roles/pubsub.publisher"
  ]

  depends_on = [google_project_service_identity.service_identity]
}

# PubSub needs these minimum permissions (GCS > EventArc > Workflow)
module "member_roles_pubsub_service_account" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = local.service_accounts_default.pubsub
  prefix                  = "serviceAccount"
  project_id              = local.project.id
  project_roles = [
    # PubSub
    "roles/iam.serviceAccountTokenCreator"
  ]

  depends_on = [google_project_service_identity.service_identity]
}

# Transcoder API service accounts needs to be able to read from GCS -input bucket and write to -output
module "member_roles_transcoder_service_account" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = local.service_accounts_default.transcoder
  prefix                  = "serviceAccount"
  project_id              = local.project.id
  project_roles = [
    # Cloud Storage
    "roles/storage.objectUser",
    "roles/storage.objectViewer"
  ]

  depends_on = [google_project_service_identity.service_identity]
}

/*
# BigQuery Connection to Google Cloud Storage (GCS) using SA
resource "google_project_iam_member" "bigquery_sa_objects" {
  role    = "roles/storage.objectViewer"
  project = local.project.id
  member  = "serviceAccount:${resource.google_bigquery_connection.cloud_resource_connection.cloud_resource[0].service_account_id}"
}

# Logs Sink SA needs to be able to write to BigQuery
resource "google_project_iam_binding" "bq-log-sink-writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"

  members = [
    google_logging_project_sink.bq-log-sink-gke-events.writer_identity,
    google_logging_project_sink.bq-log-sink-workflow-events.writer_identity,
    google_logging_project_sink.bq-log-sink-batch-events.writer_identity
  ]
}
*/

# Create a service account for BigQuery Scheduled
resource "google_service_account" "sa_bq_scheduled" {
  account_id   = "sa-${var.customer_id}-bq-scheduled"
  display_name = "TF - BigQuery Scheduled SA"
  project      = local.project.id
}

# grant bigquery admin role to the service account so that scheduled query can run
resource "google_project_iam_member" "bq-scheduled-query-sa-iam" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.sa_bq_scheduled.email}"
  depends_on = [
    google_service_account.sa_bq_scheduled
  ]
}

resource "google_project_iam_member" "bq-scheduled-query-sa-permission" {
  project = var.project_id
  role    = "roles/iam.serviceAccountShortTermTokenMinter"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
}
