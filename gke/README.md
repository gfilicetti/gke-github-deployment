# GKE Setup and Configuration

In this section, we will setup and configure components on GKE that are used in this demo.

We will be using [Skaffold](https://skaffold.dev/docs/) to stand up the Kubernetes configuration.

## Configuring Common Components

Even though Terraform has already been run and our resources provisioned, we will call out to it to get its output values. For more information on what is provisioned see the [Terraform instructions here](../terraform/README.md).

The Skaffold file for common components can be [found here](./common/skaffold.yaml).

## Configuring Kueue

For Kueue, we'll be doing two things: 
- Using Skaffold to [install the Kueue framework](./skaffold.yaml) 
- Using Skaffold to [set up Kueue](./kueue/skaffold.yaml) to our specs. 

## Setup script

We will run one script to setup both the common components and Kueue as per the above.

This script will:

- Run Terraform
    - This will be a no-op because you've already run it, but we need to get the output variables.
- Replace tokens in all config files in the `gke` folder with the real values that Terraform outputs.
    - [See below](#token-replacement-details) for details on how token replacement is done.
- Run Skaffold to install Kueue
- Run Skaffold for basic configuration
- Run Skaffold to configure Kueue

> **NOTE:** This installation script can take 5-10 minutes, please be patient.

Run this command: 

```bash
bash ./scripts/setup-gke.sh
```

### Token Replacement Details
In various .yaml files we need to use values that are output from Terraform.

This is done by token substitution. We search for the **names** of Terraform outputs and replace them with the **returned values**.

We search all `*.yaml` files in this `gke` folder recursively for any of the output names below and replace them with the value of the output from the Terraform run.

|TF Output Name|Example Value|
|---|---|
|`customer_id`|`gcp`|
|`project_id`|`transcoding-on-gke-pilot-11`|
|`region`|`us-central1`|
|`gke_name`|`gke-gcp-test`|
|`job_namespace`|`jobs`|
|`input_bucket`|`gcs-transcoding-on-gke-pilot-11-gcp-test-input`|
|`output_bucket`|`gcs-transcoding-on-gke-pilot-11-gcp-test-output`|

## Uninstalling Kueue

To uninstall queue, run this Skaffold command:

```bash
skaffold delete -m kueue-install
```

