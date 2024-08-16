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

data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_default_service_account" "default" {
}

# Create a service account for GKE cluster
resource "google_service_account" "sa_gke_cluster" {
  account_id   = "sa-${var.customer_id}-gke-cluster"
  display_name = "TF - GKE cluster SA"
  project      = var.project_id
}

resource "google_service_account_iam_binding" "sa_gke_cluster_wi_binding" {
  service_account_id = google_service_account.sa_gke_cluster.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.job_namespace}/k8s-sa-cluster]",
  ]
  depends_on = [
    module.gke
  ]
}

module "member_roles_gke_cluster" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = google_service_account.sa_gke_cluster.email
  prefix                  = "serviceAccount"
  project_id              = var.project_id
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
}

# Add roles to the default Cloud Build service account
module "member_roles_cloudbuild" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  prefix                  = "serviceAccount"
  project_id              = var.project_id
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
}


module "member_roles_default_compute" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = data.google_compute_default_service_account.default.email
  prefix                  = "serviceAccount"
  project_id              = var.project_id
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
    # GKE
    "roles/container.developer",
  ]
}

# Built in GCP Service Account (SA) permissions

# Enable Eventarc API
resource "google_project_service" "eventarc" {
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

# Enable Pub/Sub API
resource "google_project_service" "pubsub" {
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# Create a dedicated service account
resource "google_service_account" "eventarc" {
  account_id   = "eventarc-trigger-sa"
  display_name = "Eventarc Trigger Service Account"
}

# Grant permission to receive Eventarc events
resource "google_project_iam_member" "eventreceiver" {
  project = data.google_project.project.id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc.email}"
}

# Grant permission to publish events to Workflows
resource "google_project_iam_member" "eventworkflowinvoke" {
  project = data.google_project.project.id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.eventarc.email}"
}

# Google Cloud Storage (GCS) default service account needs permission to publish 
# PubSub messages (EventArc)
resource "google_project_service_identity" "storage_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "storage.googleapis.com"
}

resource "google_project_iam_member" "storage_sa_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  # storage_sa.member does not return an email address
  # gcloud beta services identity create --service storage.googleapis.com doesn't either
  # hard code the email address for this GCP managed SA 
  member = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# PubSub needs these minimum permissions (GCS > EventArc > Workflow)
resource "google_project_service_identity" "pubsub_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "pubsub.googleapis.com"
}

resource "google_project_iam_member" "pubsub_sa_token" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = google_project_service_identity.pubsub_sa.member
}

# Transcoder API service accounts needs to be able to read from 
# GCS -input bucket and write to -output
resource "google_project_service_identity" "transcoder_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "transcoder.googleapis.com"
}

resource "google_project_iam_member" "transcoder_sa_gcs_readwrite" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = google_project_service_identity.transcoder_sa.member
}

resource "google_project_iam_member" "transcoder_sa_gcs_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = google_project_service_identity.transcoder_sa.member
}
