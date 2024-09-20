# Terraform
This folder contains Terraform configuration files to provision the infrastructure needed for this project.

## Provisioning Infrastructure
The following steps will walk you through setting up **Terraform** to provision infrastructure in Google Cloud.

1. Create remote state for Terraform in Google Cloud Storage and a Terraform `tfvars` file using
your project id to create unique variable names:

    ```bash
    bash ./scripts/setup-tf.sh
    ```

2. Deploy infrastructure with Terraform:

    ```bash
    cd ./terraform
    ```
    ```bash
    terraform init -backend-config="bucket=bkt-tfstate-$(gcloud config get project)"
    terraform plan -out=out.tfplan
    terraform apply "out.tfplan"
    ```

> __Note:__ The deployment of cloud resources can take between 5 - 10 minutes.

> __Note:__ If you get the error: `Permission denied while using the Eventarc Service` you will need to run these Terraform commands to fix the error:

```bash
terraform plan -out=out.tfplan
terraform apply "out.tfplan"
```

## Tearing Down Infrastructure

1. Tear down all infrastructure created using Terraform:

    ```bash
    cd ./terraform
    terraform destroy
    ```

## Terraform Infrastructure Details

### IAM bindings reference

**Project:** <i>[project_id]</i>

| members | roles |
|---|---|
|<b>user</b><br><small><i>User</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |
|<b>`google_service_account.eventarc`</b><br><small><i>Service account</i></small>| [roles/eventarc.eventReceiver](https://cloud.google.com/iam/docs/understanding-roles#eventarc.eventReceiver) · [roles/workflows.invoker](https://cloud.google.com/iam/docs/understanding-roles#workflows.invoker) |
|<b>`google_service_account.sa-gke-cluster`</b><br><small><i>Service account</i></small>| [roles/artifactregistry.reader](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.reader) · [roles/cloudtrace.agent](https://cloud.google.com/iam/docs/understanding-roles#cloudtrace.agent) · [roles/container.admin](https://cloud.google.com/iam/docs/understanding-roles#container.admin) · [roles/container.clusterAdmin](https://cloud.google.com/iam/docs/understanding-roles#container.clusterAdmin) · [roles/container.developer](https://cloud.google.com/iam/docs/understanding-roles#container.developer) · [roles/container.nodeServiceAgent](https://cloud.google.com/iam/docs/understanding-roles#container.nodeServiceAgent) · [roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) · [roles/monitoring.metricWriter](https://cloud.google.com/iam/docs/understanding-roles#monitoring.metricWriter) · [roles/monitoring.viewer](https://cloud.google.com/iam/docs/understanding-roles#monitoring.viewer) · [roles/stackdriver.resourceMetadata.writer](https://cloud.google.com/iam/docs/understanding-roles#stackdriver.resourceMetadata.writer) · [roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) · [roles/storage.objectUser](https://cloud.google.com/iam/docs/understanding-roles#storage.objectUser) |
|<b>`data.google_compute_default_service_account.default.email`</b><br><small><i>Cloud Compute default service account</i></small>| [roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) · [roles/artifactregistry.writer](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.writer) · [roles/artifactregistry.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.serviceAgent) · [roles/artifactregistry.reader](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.reader) · [roles/batch.jobsEditor](https://cloud.google.com/iam/docs/understanding-roles#batch.jobsEditor) · [roles/batch.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#batch.serviceAgent) · [roles/batch.agentReporter](https://cloud.google.com/iam/docs/understanding-roles#batch.agentReporter) · [roles/eventarc.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#eventarc.serviceAgent) · [roles/eventarc.eventReceiver](https://cloud.google.com/iam/docs/understanding-roles#eventarc.eventReceiver) · [roles/pubsub.publisher](https://cloud.google.com/iam/docs/understanding-roles#pubsub.publisher) · [roles/container.developer](https://cloud.google.com/iam/docs/understanding-roles#container.developer) · [roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) · [roles/storage.objectUser](https://cloud.google.com/iam/docs/understanding-roles#storage.objectUser) · [roles/transcoder.admin](https://cloud.google.com/iam/docs/understanding-roles#transcoder.admin) · [roles/transcoder.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#transcoder.serviceAgent) · [roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) · [roles/workflows.invoker](https://cloud.google.com/iam/docs/understanding-roles#workflows.invoker) · [roles/workflows.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#workflows.serviceAgent) |
|<b>`${local.project.number}@cloudbuild.gserviceaccount.com`</b><br><small><i>Cloud Build default service account</i></small>| [roles/artifactregistry.reader](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.reader) · [roles/artifactregistry.repoAdmin](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.repoAdmin) · [roles/artifactregistry.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.serviceAgent) · [roles/batch.agentReporter](https://cloud.google.com/iam/docs/understanding-roles#batch.agentReporter) · [roles/batch.jobsEditor](https://cloud.google.com/iam/docs/understanding-roles#batch.jobsEditor) · [roles/batch.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#batch.serviceAgent) · [roles/cloudbuild.builds](https://cloud.google.com/iam/docs/understanding-roles#cloudbuild.builds) · [roles/cloudbuild.connectionAdmin](https://cloud.google.com/iam/docs/understanding-roles#cloudbuild.connectionAdmin) · [roles/container.developer](https://cloud.google.com/iam/docs/understanding-roles#container.developer) · [roles/eventarc.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#eventarc.serviceAgent) · [roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) · [roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) · [roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) · [roles/storage.objectUser](https://cloud.google.com/iam/docs/understanding-roles#storage.objectUser) · [roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) · [roles/transcoder.admin](https://cloud.google.com/iam/docs/understanding-roles#transcoder.admin) · [roles/transcoder.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#transcoder.serviceAgent) · [roles/workflows.invoker](https://cloud.google.com/iam/docs/understanding-roles#workflows.invoker) · [roles/workflows.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#workflows.serviceAgent) |
|<b>`data.google_storage_project_service_account.default.email_address`</b><br><small><i>Cloud Storage service agent</i></small>| [roles/pubsub.publisher](https://cloud.google.com/iam/docs/understanding-roles#pubsub.publisher) |
|<b>`service-${local.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com`</b><br><small><i>Cloud Pub/Sub service agent</i></small>| [roles/iam.serviceAccountTokenCreator](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountTokenCreator) |
|<b>`service-${local.project.number}@gcp-sa-transcoder.iam.gserviceaccount.com`</b><br><small><i>Cloud Transcoder service agent</i></small>| [roles/storage.objectUser](https://cloud.google.com/iam/docs/understanding-roles#storage.objectUser) · [roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |


### Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Define Terraform local variabls and service account defaults. |  | `google_project_service_identity.service_identity` |
| [cicd.tf](./cicd.tf) | Define Artifact Registry repository for container images. |  | `google_artifact_registry_repository.repo` |
| [gcs.tf](./gcs.tf) | GCS buckets for transcoding input/output artifacts |  | `google_storage_bucket.gcs-input`, `google_storage_bucket.gcs-output` |
| [gke.tf](./gke.tf) | GKE cluster for transcoding jobs. | [`gke`](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/beta-autopilot-private-cluster) |  |
| [iam.tf](./iam.tf) | IAM resources for project needed by Cloud resources. | [`member_roles_cloudbuild`, `member_roles_default_compute`, `member_roles_eventarc_trigger`, `member_roles_gcs_service_account`, `member_roles_gke_cluster`, `member_roles_pubsub_service_account`, `member_roles_transcoder_service_account`](https://registry.terraform.io/modules/terraform-google-modules/iam/google/latest/submodules/member_iam) | `google_service_account.eventarc`, `google_service_account.sa_gke_cluster`, `google_service_account_iam_binding.sa_gke_cluster_wi_binding` |
| [net.tf](./net.tf) | VPC network and firewall rules. | [`cloud-nat`](https://registry.terraform.io/modules/terraform-google-modules/cloud-nat/google/latest), [`vpc`](https://registry.terraform.io/modules/terraform-google-modules/network/google/latest) | `google_compute_router.router` |

### Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| project_id | Unique project ID to host project resources. | `string` | ✓ | "" |
| customer_id | Unique customer ID to name TF created resources. | `string` | ✓ | "gcp" |
| region | Region that will be used for all required resources. | `string` | ✓ | "us-central1" |
| subnet | Subnet IP address range for VPC. | `string` | ✓ | "10.128.0.0/20" |
| job_namespace | GKE namespace for jobs for WI configuration. | `string` | ✓ | "jobs" |

### Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| project_id | Unique project ID to host project resources. | ✓ | GKE |
| customer_id | Unique customer ID to name TF created resources. | x | GKE |
| region | Region that will be used for all required resources. | x | GKE |
| subnet | Subnet IP address range for VPC. | x | GKE |
| job_namespace | GKE namespace for jobs for WI configuration. | x  | GKE |
