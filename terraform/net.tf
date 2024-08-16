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

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "9.1.0"

  project_id   = local.project.id
  network_name = "vpc-${var.customer_id}"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "sn-${var.customer_id}-${var.region}"
      subnet_ip             = "${var.subnet}"
      subnet_region         = "${var.region}"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Subnet for var.region"
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    "sn-${var.customer_id}-${var.region}" = [
      {
        range_name    = "sn-${var.customer_id}-${var.region}-pods1"
        ip_cidr_range = "172.16.0.0/16"
      },
      {
        range_name    = "sn-${var.customer_id}-${var.region}-svcs1"
        ip_cidr_range = "192.168.0.0/26"
      },
    ]
  }
}

# [START cloudnat_router_nat_gke]
resource "google_compute_router" "router" {
  project    = local.project.id
  name       = "nat-router-${var.customer_id}"
  network    = module.vpc.network_name
  region     = var.region

  depends_on = [ module.vpc ]
}


module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 5.0"
  project_id                         = local.project.id
  region                             = var.region
  router                             = google_compute_router.router.name
  name                               = "nat-config-${var.customer_id}"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
# [END cloudnat_router_nat_gke]
