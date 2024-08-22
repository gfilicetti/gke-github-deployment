#!/bin/bash
# setup-gke.sh LOCAL_STATE AUTO_APPROVE
# This script sets up GKE with common configuration and all the extra things we're installing
# NOTE: This is the untouched script used initially

#asset vars
LOCAL_STATE=${1:-"false"}
AUTO_APPROVE=${2:-"false"}

#project vars
LOCATION=${5:-"us-central1"}
PROJECT_ID=${6:-$(gcloud config get project)}

#Clone the repo
git clone git@github.com:ggiovanejr/gke-github-deployment-giovanejr.git

cd gke-github-deployment-giovanejr
cd terraform/

#Get project_ID and adding to the tfvars
export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
cat terraform.tfvars.example | sed -e "s:your-unique-project-id:$PROJECT_ID:g" > terraform.tfvars

#Optional removing GCS backend
sed -i -e 's:backend:#backend:g' provider.tf

#Terraform
terraform init
terraform plan
terraform apply -auto-approve

#Replacing variables
if gcloud container clusters get-credentials `terraform output -raw gke_name`  --region `terraform output -raw region` --project `terraform output -raw project_id`; then
  for i in `terraform output|awk '{print $1}'`; do 
    value=`terraform output -raw $i`; 
    for j in ` grep $i -rl ../gke/*`; do 
      sed -i -e "s:$i:$value:g" $j
    done
  done
fi

#Deploying
cd ../gke/
skaffold run -m kueue-install
sleep 20 #Recommended to avoid failures with the kueue installation
skaffold run -m gke-skaffold-config
