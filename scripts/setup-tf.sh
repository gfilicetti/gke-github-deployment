#!/bin/bash

# Source environment variables from .env file (see scripts/setup-env.sh)
source .env

# Terraform directory
TF_DIR=$(pwd)/terraform

gcloud storage buckets create "gs://bkt-tfstate-${GCP_PROJECT_ID}" \
  --project="${GCP_PROJECT_ID}" \
  --location=us-central1 \
  --public-access-prevention \
  --uniform-bucket-level-access

gsutil versioning set on "gs://bkt-tfstate-${GCP_PROJECT_ID}"

cp $TF_DIR/terraform.tfvars.example $TF_DIR/terraform.tfvars

sed -i "s/your-unique-project-id/$GCP_PROJECT_ID/g" $TF_DIR/terraform.tfvars
sed -i "s/your-customer-id/$GCP_CUSTOMER_ID/g" $TF_DIR/terraform.tfvars
sed -i "s/your-cloud-location/$GCP_LOCATION/g" $TF_DIR/terraform.tfvars
