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

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  deletion_protection        = false
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  version                    = "32.0.0"
  project_id                 = local.project.id
  name                       = "gke-${var.customer_id}-test"
  region                     = var.region
  network                    = module.vpc.network_name
  network_tags               = ["batch-server"]
  subnetwork                 = "sn-${var.customer_id}-${var.region}"
  ip_range_pods              = "sn-${var.customer_id}-${var.region}-pods1"
  ip_range_services          = "sn-${var.customer_id}-${var.region}-svcs1"
  horizontal_pod_autoscaling = true
  release_channel            = "RAPID" # RAPID was chosen for L4 support.
  kubernetes_version         = "1.29"  # We need the tip of 1.28 or 1.29 (not just default)
  service_account            = google_service_account.sa_gke_cluster.email
  # Google Cloud Storage (GCS) Fuse
  gcs_fuse_csi_driver        = true
  # enable_private_endpoint    = true
  enable_private_nodes       = true
  # master_ipv4_cidr_block     = "10.0.0.0/28"
  # master_authorized_networks = [{ cidr_block = "${var.subnet}", display_name = "internal" }]
  master_authorized_networks = [{ cidr_block = "0.0.0.0/0", display_name = "all" }]
  # Need to allow 48 hour window in rolling 32 days For `maintenance_start_time`
  # & `end_time` only the specified time of the day is used, the specified date
  # is ignored (https://cloud.google.com/composer/docs/specify-maintenance-windows#terraform)
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SU"
  maintenance_start_time = "2023-01-02T07:00:00Z"
  maintenance_end_time   = "2023-01-02T19:00:00Z"

  depends_on = [
    google_service_account.sa_gke_cluster,
    module.vpc,
    module.cloud-nat
  ]
}
