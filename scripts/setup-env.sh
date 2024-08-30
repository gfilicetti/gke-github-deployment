#!/bin/bash

if ! [ $(command -v gh) ]
then
  echo "bash: gh: command not found"
  echo "condsider installing gh cli at: https://github.com/cli/cli#installation"
fi

# Obtain possible defaults of key environment variables:
_GITHUB_ORG=$(gh repo view --json owner -q ".owner.login")
_GITHUB_REPO=$(gh repo view --json name -q ".name")
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

gh repo set-default ${GITHUB_ORG}/${GITHUB_REPO}

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
