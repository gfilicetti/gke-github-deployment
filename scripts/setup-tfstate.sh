#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)

gcloud storage buckets create "gs://bkt-tfstate-${PROJECT_ID}" \
  --project="${PROJECT_ID}" \
  --location=us-central1 \
  --public-access-prevention \
  --uniform-bucket-level-access

gsutil versioning set on "gs://bkt-tfstate-${PROJECT_ID}"
