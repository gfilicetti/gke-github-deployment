# Deploy a Managed Workflow

A common use-case is to automate the processing of a newly uploaded video to [Google Cloud Storage](https://cloud.google.com/storage/docs) (GCS) and kick off the transcoding of the video automatically. We'll make use of [EventArc](https://cloud.google.com/eventarc/docs) and a [Managed Workflow](https://cloud.google.com/workflows/docs) to listen for upload events and decide which backend to send the job to. We'll make use of several backend services depending on the use case: [Transcoder API](https://cloud.google.com/transcoder/docs), [Batch Compute API](https://cloud.google.com/batch/docs), and a [Kubernetes Engine kueue](https://cloud.google.com/kubernetes-engine/docs/tutorials/kueue-intro).

*Extends this [EventArc guide](https://cloud.google.com/eventarc/docs/workflows/route-trigger-cloud-storage).*

> TODO: diagram Upload a file to -input GCS bucket -> eventarc -> workflow -> {api, batch, k8s} -> -output gcs bucket

## Prerequisites
1. Create a new GCP Project and ensure [Billing is enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#console)
1. Create a Google Cloud Storage (GCS) Bucket for `-upload`
1. Create a Google Cloud Storage (GCS) Bucket for `-output`
1. Use the [default compute engine service account](https://cloud.google.com/workflows/docs/authentication#default-sa) or create a new one. Grant the service account permission to:
    - `roles/batch.jobsEditor`
    - `roles/batch.serviceAgent`
    - `roles/batch.agentReporter`
    - `roles/eventarc.serviceAgent`
    - `roles/storage.objectUser`
    - `roles/storage.objectViewer`
    - `roles/transcoder.admin`
    - `roles/transcoder.serviceAgent`
    - `roles/workflows.invoker`
    - `roles/workflows.serviceAgent`
    - `roles/logging.logWriter`
    - `roles/artifactregistry.serviceAgent`
    - `roles/artifactregistry.repoAdmin`
    - `roles/artifactregistry.reader`
    - `roles/iam.serviceAccountUser`

## Enable services

```
gcloud services enable eventarc.googleapis.com \
    eventarcpublishing.googleapis.com \
    workflows.googleapis.com \
    workflowexecutions.googleapis.com \
    compute.googleapis.com \
    storage.googleapis.com
```

## Set Parameters

```
export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
export DEFAULT_SA=$(gcloud iam service-accounts list --filter="Default compute service account" --format="value(email)")
export LOCATION="us-central1"
export WORKFLOW_NAME="workflow-gcs-transcoding-batch"
export GCS_INPUT_BUCKET="alanpoole-transcoding-on-gke-input"
export GCS_OUTPUT_BUCKET="alanpoole-transcoding-on-gke-output"
```

## Create a Workflow

Using Managed [Workflows](https://console.cloud.google.com/workflows) to create a services of steps to decide which backend transcoder service to send the newly uploaded file event to.

```
gcloud workflows deploy $WORKFLOW_NAME \
    --description="A workflow that decides which backend transcoder service to send a newly uploaded GCP video file." \
    --source=workflow.yaml \
    --location=$LOCATION \
    --service-account=$DEFAULT_SA \
    --env-vars-file=environment-variables.yaml
```

## Create an Event Tigger

Using [EventArc](https://console.cloud.google.com/eventarc/triggers) to set a event trigger when a new Google Cloud Storage (GCS) object is uploaded ("finalized") and to call the workflow.

```
gcloud eventarc triggers create $WORKFLOW_NAME-trigger \
    --location=$LOCATION \
    --destination-workflow=$WORKFLOW_NAME  \
    --destination-workflow-location=$LOCATION \
    --event-filters="type=google.cloud.storage.object.v1.finalized" \
    --event-filters="bucket=${GCS_INPUT_BUCKET}" \
    --service-account=$DEFAULT_SA
```