#!/bin/bash
# setup-gke.sh LOCAL_STATE AUTO_APPROVE

# Command line params
LOCAL_STATE=${1:-"false"}
AUTO_APPROVE=${2:-"false"}

# Local vars
PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

# get into the terraform folder
cd ../terraform

# add the project ID to tfvars
cat terraform.tfvars.example | sed -e "s:your-unique-project-id:$PROJECT_ID:g" > terraform.tfvars

# Optional: If we're using local state, we will remove the GCS backend setting from terraform
if [[ "$LOCAL_STATE" != "false" ]]; then
    sed -i -e 's:backend:#backend:g' provider.tf

# Run Terraform (auto approve if the flag is set)
terraform init -backend-config="bucket=bkt-tfstate-${PROJECT_ID}"
terraform plan -out=out.tfplan
if [[ "$AUTO_APPROVE" != "false" ]]; then
    terraform apply "out.tfplan" -auto-approve
else
    terraform apply "out.tfplan"

# Get back into the GKE folder
cd ../gke

# Replace variables in GKE configuration files
# Get Terraform output in json format
TF_OUTPUT_JSON=`terraform output -json`

TF_CLUSTER=`jq -r '.gke_name.value' <<< $TF_OUTPUT_JSON`
TF_REGION=`jq -r '.region.value' <<< $TF_OUTPUT_JSON`
TF_PROJECT=`jq -r '.project_id.value' <<< $TF_OUTPUT_JSON`

# Test if our outputs are good by trying to get k8s creds for our cluster
if gcloud container clusters get-credentials $TF_CLUSTER --region $TF_REGION --project $TF_PROJECT; then
  # Create an array of comma separated key value pairs in the bash array called "outputs"
  readarray -t outputs <<< `jq -r 'to_entries[] | "\(.key),\(.value.value)"' <<< $TF_OUTPUT_JSON`

  # Loop through each output, grep for the key in all files and replace it with the value if found
  for output in ${outputs[@]}; do
    key=`awk -F',' '{print $1}' <<< "$output"`
    value=`awk -F',' '{print $2}' <<< "$output"`
    for file in `grep $key -rl ../gke/*`; do
      printf "sed -i -e 's:$key:$value:g' $file\n"
    done
  done
fi

# Deploy with Skaffold (it is recommended to pause between calls to avoid a race condition)
skaffold run -m kueue-install
sleep 20 
skaffold run -m gke-skaffold-config
