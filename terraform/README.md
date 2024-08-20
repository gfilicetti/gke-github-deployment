# Terraform
This folder contains Terraform configuration files to provision the infrastructure needed for this project.

## Provisioning Infrastructure
The following steps will walk you through the setup guide for running **Terraform** as the deployment process for cloud environment.

1. Create remote state for Terraform in Google Cloud Storage:

    ```bash
    sh ./scripts/setup-tfstate.sh
    ```

2. Create a Terraform tfvars file using your project id to create unique variable names:

    ```bash
    cd ./terraform
    cat terraform.example.tfvars | sed -e "s:your-unique-project-id:$PROJECT_ID:g" > terraform.tfvars
    ```

3. Deploy infrastructure with Terraform

    ```bash
    cd ./terraform
    terraform init
    terraform plan
    terraform apply
    ```

> __Note:__ The deployment of cloud resources can take between 5 - 10 minutes.

## Tearing Down Infrastructure

1. Delete infrastructure with Terraform

    ```bash
    cd ./terraform
    terraform destroy
    ```