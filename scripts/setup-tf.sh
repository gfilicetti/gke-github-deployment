#!/bin/bash

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Source environment variables from .env file (see scripts/setup-env.sh)
source .env

# Terraform directory
TF_DIR=$(pwd)/terraform

# first check that we already have the TF state bucket created
if gcloud -q storage buckets describe gs://bkt-tfstate-${GCP_PROJECT_ID} >/dev/null 2>&1; then
  printf "Terraform remote state bucket is found, continuing...\n"
else
  # Create Google Cloud Storage bucket for TF
  gcloud storage buckets create "gs://bkt-tfstate-${GCP_PROJECT_ID}" \
    --project="${GCP_PROJECT_ID}" \
    --location=us-central1 \
    --public-access-prevention \
    --uniform-bucket-level-access

  gsutil versioning set on "gs://bkt-tfstate-${GCP_PROJECT_ID}"
fi

cp $TF_DIR/terraform.tfvars.example $TF_DIR/terraform.tfvars

sed -i "s/your-unique-project-id/$GCP_PROJECT_ID/g" $TF_DIR/terraform.tfvars
sed -i "s/your-customer-id/$GCP_CUSTOMER_ID/g" $TF_DIR/terraform.tfvars
sed -i "s/your-cloud-location/$GCP_LOCATION/g" $TF_DIR/terraform.tfvars
