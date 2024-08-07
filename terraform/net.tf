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
  version = "8.0.0"

  project_id   = var.project_id
  network_name = "vpc-${var.customer_id}"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "sn-${var.customer_id}-${var.region}"
      subnet_ip             = "10.128.0.0/20"
      subnet_region         = "${var.region}"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Subnet for var.region"
    }
  ]

  secondary_ranges = {
    "sn-usw1" = [
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

  # ingress_rules = [
  #   {
  #     name          = "fw-batch-server"
  #     description   = "Allow batch server traffic"
  #     priority      = 1000
  #     source_ranges = ["0.0.0.0/0"],
  #     target_tags   = ["batch-server"]
  #     allow = [
  #       {
  #         protocol = "udp"
  #         ports    = ["7000-8000"]
  #       }
  #     ]
  #   }
  # ]
}
