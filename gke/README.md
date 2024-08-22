# GKE Setup and Configuration

In this section, we will setup and configure components on GKE that are used in this demo.

We will be using [Skaffold](https://skaffold.dev/docs/) to stand up the Kubernetes configuration.

## Configuring Common Components

If you haven't already, please make sure the infrastructure is setup already using Terraform. Instructions can be [found here](../terraform/README.md).

The Skaffold file for common components can be [found here](./common/skaffold.yaml).

## Configuring Kueue

For Kueue, we'll be doing two things, using Skaffold to install the framework itself and then using Skaffold to set up Kueue to our specs. 

## Setup script

Run this one script to setup everything, namely it will:

- Run Terraform
    - This should be a no-op because you've already run it, but we need to get the output variables.
- Replace tokens in all config files in the `gke` folder with the real values that Terraform outputs.
- Run Skaffold to install Kueue
- Run Skaffold for basic configuration
- Run Skaffold to configure Kueue

```bash
sh ./scripts/setup-gke.sh
```
