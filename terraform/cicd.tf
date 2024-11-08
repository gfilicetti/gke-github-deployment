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

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "repo-batch-jobs"
  description   = "Batch jobs Artifact Registry."
  format        = "DOCKER"
}

# Cloud Deploy | Pipeline
resource "google_clouddeploy_delivery_pipeline" "primary" {
  depends_on  = [module.cicd_execution_service_accounts, module.cicd_trigger_service_account]
  name        = "ffmpeg-api-cd"
  description = "Delivery pipeline for FFMPEG API (in Python)."
  project     = local.project.id
  location    = var.region

  serial_pipeline {
    stages {
      profiles  = ["profile-dev"]
      target_id = "target-primary-gke-dev"
      deploy_parameters {
        values = {
          chartVersion = "1.0.0"
        }
      }
      strategy {
        standard {
          verify = true
        }
      }
    }

    stages {
      profiles  = ["profile-staging"]
      target_id = "target-primary-gke-staging"
    }

    stages {
      profiles  = ["profile-prod"]
      target_id = "target-primary-gke-prod"
    }
  }

  annotations = {}

  labels = {
    lang = "python"
  }
}

# Cloud Deploy | Targets
resource "google_clouddeploy_target" "primary-dev" {
  depends_on  = [module.cicd_execution_service_accounts, module.cicd_trigger_service_account]
  name        = "target-primary-gke-dev"
  description = "01 Primary cluster for dev (internal, autopush, integration tests)"
  project     = local.project.id
  location    = var.region

  gke {
    cluster = module.gke.cluster_id
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY", "VERIFY"]
    service_account   = "sa-${var.customer_id}-exe-cicd@${local.project.id}.iam.gserviceaccount.com"
  }

  require_approval = false

  labels = {
    runtime = "gke"
    env = "dev"
  }

}

resource "google_clouddeploy_target" "primary-staging" {
  depends_on  = [module.cicd_execution_service_accounts, module.cicd_trigger_service_account]
  name        = "target-primary-gke-staging"
  description = "02 Primary cluster for staging (staging)"
  project     = local.project.id
  location    = var.region

  gke {
    cluster = module.gke.cluster_id
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY", "VERIFY"]
    service_account   = "sa-${var.customer_id}-exe-cicd@${local.project.id}.iam.gserviceaccount.com"
  }

  require_approval = false

  labels = {
    runtime = "gke"
    env = "staging"
  }
}

resource "google_clouddeploy_target" "primary-prod" {
  depends_on  = [module.cicd_execution_service_accounts, module.cicd_trigger_service_account]
  name        = "target-primary-gke-prod"
  description = "03 Primary cluster for prod (prod)"
  project     = local.project.id
  location    = var.region

  gke {
    cluster = module.gke.cluster_id
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY", "VERIFY"]
    service_account   = "sa-${var.customer_id}-exe-cicd@${local.project.id}.iam.gserviceaccount.com"
  }

  require_approval = true

  labels = {
    runtime = "gke"
    env = "prod"
  }
}

# Create trigger service account for Cloud Deploy

module "cicd_trigger_service_account" {
  source       = "terraform-google-modules/service-accounts/google"
  project_id   = local.project.id
  names        = ["sa-${var.customer_id}-tri-cicd"]
  display_name = "TF - CICD trigger operations"
  project_roles = [
    "${local.project.id}=>roles/cloudbuild.builds.editor",
    "${local.project.id}=>roles/cloudbuild.builds.builder",
    "${local.project.id}=>roles/clouddeploy.developer",
    "${local.project.id}=>roles/clouddeploy.releaser",
    "${local.project.id}=>roles/clouddeploy.jobRunner",
    "${local.project.id}=>roles/storage.objectAdmin"
  ]
}

# Create execution service account for Cloud Deploy

module "cicd_execution_service_accounts" {
  source        = "terraform-google-modules/service-accounts/google"
  project_id    = local.project.id
  names         = ["sa-${var.customer_id}-exe-cicd"]
  display_name  = "TF - CICD execution operations"
  project_roles = [
    "${local.project.id}=>roles/container.developer",
    "${local.project.id}=>roles/storage.objectAdmin",
    "${local.project.id}=>roles/artifactregistry.reader",
    "${local.project.id}=>roles/logging.logWriter",
  ]
}

resource "google_service_account_iam_member" "tri_sa_actas_exe_sa" {
  depends_on         = [module.cicd_execution_service_accounts, module.cicd_trigger_service_account]
  service_account_id = "projects/${local.project.id}/serviceAccounts/sa-${var.customer_id}-exe-cicd@${local.project.id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:sa-${var.customer_id}-tri-cicd@${local.project.id}.iam.gserviceaccount.com"
}
