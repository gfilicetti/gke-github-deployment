#!/bin/bash
# setup-gke.sh LOCAL_STATE AUTO_APPROVE

# Command line params
LOCAL_STATE=${1:-"false"}
AUTO_APPROVE=${2:-"false"}

# Local vars
PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

# get into the terraform folder
cd ../../terraform

# add the project ID to tfvars
cat terraform.example.tfvars | sed -e "s:your-unique-project-id:$PROJECT_ID:g" > terraform.tfvars

# Optional: Remove GCS backend and save state locally
if [[ "$LOCAL_STATE" != "false" ]]; then
    sed -i -e 's:backend:#backend:g' provider.tf

# Run Terraform (auto approve if the flag is set)
terraform init
terraform plan
if [[ "$AUTO_APPROVE" != "false" ]]; then
    terraform apply -auto-approve
else
    terraform apply

# Get back into the GKE folder
cd ../gke

# Replacing variables
if gcloud container clusters get-credentials `terraform output -raw gke_name`  --region `terraform output -raw region` --project `terraform output -raw project_id`; then
  for i in `terraform output|awk '{print $1}'`; do 
    value=`terraform output -raw $i`; 
    for j in ` grep $i -rl ../gke/*`; do 
      sed -i -e "s:$i:$value:g" $j
    done
  done
fi

# Deploy with Skaffold
skaffold run -m kueue-install
sleep 20 # Recommended to avoid race conditions with the kueue installation
skaffold run -m gke-skaffold-config
