#!/bin/bash

# Set GitHub "organization" and repo name:
GITHUB_ORG=""
GITHUB_REPO="gke-github-deployment"

read -p "Enter GitHub organization or username: " GITHUB_ORG
read -p "Enter GitHub repository name [${GITHUB_REPO}]: " GITHUB_REPO

GITHUB_REPO=${GITHUB_REPO:-${GITHUB_REPO}}

# Fetch Project ID:
PROJECT_ID=$(gcloud config get-value project)

# Fetch Project Number from Project ID:
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

# GitHub Actions SA:
GH_ACTIONS_SA="sa-tf-gh-actions"

# 1. Create a Google Cloud Service Account.
gcloud iam service-accounts create "${GH_ACTIONS_SA}" \
  --project "${PROJECT_ID}"

# 2. Create a Workload Identity Pool.
gcloud iam workload-identity-pools create "github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# 3. Create a Workload Identity Provider in that pool.
gcloud iam workload-identity-pools providers create-oidc "${GITHUB_ORG:0:5}-${GITHUB_REPO}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github" \
  --display-name="GitHub repo Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")

# 4. Allow authentications from the Workload Identity Pool to your Google Cloud Service Account.
gcloud iam service-accounts add-iam-policy-binding "${GH_ACTIONS_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

# 5. Extract the Workload Identity Provider resource name.
GCP_WI_PROVIDER_ID=$(gcloud iam workload-identity-pools providers describe "${GITHUB_ORG:0:5}-${GITHUB_REPO}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github" \
  --format="value(name)")

cat << EOF

----- GITHUB ACTIONS ENV KEY/VALUE -----

GCP_PROJECT_ID: ${PROJECT_ID}
GCP_WI_PROVIDER_ID: ${GCP_WI_PROVIDER_ID}

----------------------------------------
EOF


