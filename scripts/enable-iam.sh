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

# Add roles to Github Actions Google Cloud Service Account.
for SUCCINCT_ROLE in \
    artifactregistry.admin \
    bigquery.admin \
    cloudbuild.connectionAdmin \
    cloudbuild.builds.editor \
    clouddeploy.developer \
    clouddeploy.jobRunner \
    clouddeploy.operator \
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
