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

if ! [ $(command -v gh) ]
then
  echo "bash: gh: command not found"
  echo "Consider installing gh cli at: https://github.com/cli/cli#installation"
fi

# figure out if we're logged into the gh CLI
gh auth status > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "gh: command found and logged into GitHub"
  GH_AVAILABLE=true
fi

# Obtain possible defaults of key environment variables:
_GITHUB_REPO="gke-github-deployment"
if [ $GH_AVAILABLE ]; then
  _GITHUB_ORG=$(gh repo view --json owner -q ".owner.login")
  _GITHUB_REPO=$(gh repo view --json name -q ".name")
fi
_GCP_SA_GITHUB_ACTIONS="sa-tf-gh-actions"
_GCP_PROJECT_ID=$(gcloud config get-value project)
_GCP_LOCATION=$(gcloud config get-value compute/region)
_GCP_CUSTOMER_ID="gcp"

# Request acceptance of defaults or alternatives
read -p "Enter GitHub organization or owner [${_GITHUB_ORG}]: " GITHUB_ORG
read -p "Enter GitHub repository name [${_GITHUB_REPO}]: " GITHUB_REPO
read -p "Enter GCP project ID [${_GCP_PROJECT_ID}]: " GCP_PROJECT_ID
read -p "Enter default value region for this setup [${_GCP_LOCATION}]: " GCP_LOCATION
read -p "Enter short (3-5 char) identifier for cloud resources (e.g. gcp) [$_GCP_CUSTOMER_ID]: " GCP_CUSTOMER_ID

GITHUB_ORG="${GITHUB_ORG:-`echo $_GITHUB_ORG`}"
GITHUB_REPO="${GITHUB_REPO:-`echo $_GITHUB_REPO`}"
GCP_SA_GITHUB_ACTIONS="${GCP_SA_GITHUB_ACTIONS:-`echo $_GCP_SA_GITHUB_ACTIONS`}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-`echo $_GCP_PROJECT_ID`}"
GCP_LOCATION="${GCP_LOCATION:-`echo $_GCP_LOCATION`}"
GCP_CUSTOMER_ID="${GCP_CUSTOMER_ID:-`echo $_GCP_CUSTOMER_ID`}"

gcloud config set project ${GCP_PROJECT_ID} 2> /dev/null
gcloud config set compute/region ${GCP_LOCATION} 2> /dev/null

if [ $GH_AVAILABLE ]; then
  gh repo set-default ${GITHUB_ORG}/${GITHUB_REPO}
fi

GCLOUD_CONFIG=$(gcloud config list 2> /dev/null)

cat << EOF

----------------------------------------
-------- GOOGLE CLOUD CONFIGURED -------
----------------------------------------

${GCLOUD_CONFIG}

----------------------------------------
----- GITHUB ACTIONS ENV KEY/VALUE -----
----------------------------------------

GITHUB_ORG:            ${GITHUB_ORG}
GITHUB_REPO:           ${GITHUB_REPO}
GCP_SA_GITHUB_ACTIONS: ${GCP_SA_GITHUB_ACTIONS}
GCP_PROJECT_ID:        ${GCP_PROJECT_ID}
GCP_LOCATION:          ${GCP_LOCATION}
GCP_CUSTOMER_ID:       ${GCP_CUSTOMER_ID}

GCP_GCS_SOURCE:        gcs-${GCP_PROJECT_ID}-${GCP_CUSTOMER_ID}-test-input
GCP_GCS_OUTPUT:        gcs-${GCP_PROJECT_ID}-${GCP_CUSTOMER_ID}-test-output
GCP_GKE_CLUSTER_NAME:  gke-${GCP_CUSTOMER_ID}-test

EOF

cat << EOF > .env
GITHUB_ORG="${GITHUB_ORG}"
GITHUB_REPO="${GITHUB_REPO}"
GCP_SA_GITHUB_ACTIONS="${GCP_SA_GITHUB_ACTIONS}"
GCP_PROJECT_ID="${GCP_PROJECT_ID}"
GCP_LOCATION="${GCP_LOCATION}"
GCP_CUSTOMER_ID="${GCP_CUSTOMER_ID}"
GCP_GCS_SOURCE="gcs-${GCP_PROJECT_ID}-${GCP_CUSTOMER_ID}-test-input"
GCP_GCS_OUTPUT="gcs-${GCP_PROJECT_ID}-${GCP_CUSTOMER_ID}-test-output"
GCP_GKE_CLUSTER_NAME="gke-${GCP_CUSTOMER_ID}-test"
EOF
