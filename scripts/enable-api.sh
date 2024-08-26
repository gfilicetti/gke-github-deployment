#!/bin/bash

# Enable IAM permissions for default service accounts for GKE and Cloud Build
PROJECT_ID=$(gcloud config get-value project)

# Enable all the APIs needed in our demos
gcloud services enable --project $PROJECT_ID \
  aiplatform.googleapis.com \
  artifactregistry.googleapis.com \
  batch.googleapis.com \
  cloudbuild.googleapis.com \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  containerfilesystem.googleapis.com \
  containerregistry.googleapis.com \
  eventarc.googleapis.com \
  eventarcpublishing.googleapis.com \
  iam.googleapis.com \
  pubsub.googleapis.com \
  run.googleapis.com \
  servicecontrol.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com \
  transcoder.googleapis.com \
  workflows.googleapis.com \
  workflowexecutions.googleapis.com

# Cont'd, enable APIs for BigQuery services
gcloud services enable --project $PROJECT_ID \
  bigquery.googleapis.com \
  bigquerydatatransfer.googleapis.com