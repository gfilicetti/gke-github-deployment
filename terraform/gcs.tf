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
resource "google_storage_bucket" "gcs-input" {
  name                        = "gcs-${local.project.id}-${var.customer_id}-test-input"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "gcs-output" {
  name                        = "gcs-${local.project.id}-${var.customer_id}-test-output"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
}
