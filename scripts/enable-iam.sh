#!/bin/bash

# Source environment variables from .env file (see scripts/setup-env.sh)
source .env

# Add roles to Google Cloud Service Account.
for SUCCINCT_ROLE in \
    viewer \
    artifactregistry.admin \
    bigquery.admin \
    cloudbuild.connectionAdmin \
    cloudbuild.builds.builder \
    clouddeploy.jobRunner \
    clouddeploy.releaser \
    compute.networkAdmin \
    compute.securityAdmin \
    container.clusterAdmin \
    eventarc.developer \
    iam.serviceAccountAdmin \
    iam.serviceAccountUser \
    logging.configWriter \
    pubsub.subscriber \
    resourcemanager.projectIamAdmin \
    run.developer \
    run.invoker \
    storage.admin \
    storage.objectAdmin \
    workflows.editor \
    ; do

  gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:${GCP_SA_GITHUB_ACTIONS}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/$SUCCINCT_ROLE" \
    --condition=None

done
