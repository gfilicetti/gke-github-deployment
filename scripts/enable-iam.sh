#!/bin/bash

# Enable IAM permissions for default service accounts for GKE and Cloud Build
PROJECT_ID=$(gcloud config get-value project)

# Fetch Project Number from Project ID:
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

# GitHub Actions SA:
GH_ACTIONS_SA="sa-tf-gh-actions@${PROJECT_ID}.iam.gserviceaccount.com"

# 1. Enable key Google Cloud service APIs
gcloud services enable --project $PROJECT_ID \
  aiplatform.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  containerfilesystem.googleapis.com \
  containerregistry.googleapis.com \
  iam.googleapis.com \
  servicecontrol.googleapis.com

# 2. Add roles to normal Cloud Build service account
for SUCCINCT_ROLE in \
    artifactregistry.admin \
    cloudbuild.connectionAdmin \
    cloudbuild.builds.builder \
    clouddeploy.jobRunner \
    clouddeploy.releaser \
    compute.networkAdmin \
    compute.securityAdmin \
    container.clusterAdmin \
    iam.serviceAccountAdmin \
    iam.serviceAccountUser \
    pubsub.subscriber \
    resourcemanager.projectIamAdmin \
    run.developer \
    run.invoker \
    storage.objectAdmin \
    ; do
  gcloud projects add-iam-policy-binding \
    --member="serviceAccount:${GH_ACTIONS_SA}" \
    --role "roles/$SUCCINCT_ROLE" "$PROJECT_ID" \
    --condition=None
done
