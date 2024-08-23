# GKE Setup and Configuration

In this section, we will setup and configure components on GKE that are used in this demo.

We will be using [Skaffold](https://skaffold.dev/docs/) to stand up the Kubernetes configuration.

## Configuring Common Components

If you haven't already, we will call out to Terraform to provision this project's resources. For more information on what is provisioned see the [Terraform instructions here](../terraform/README.md).

The Skaffold file for common components can be [found here](./common/skaffold.yaml).

## Configuring Kueue

For Kueue, we'll be doing two things: 
- Using Skaffold to [install the framework itself](./skaffold.yaml) 
- Using Skaffold to [set up Kueue](./kueue/skaffold.yaml) to our specs. 

## Setup script

Run this one script to setup both the common components and Kueue as per the above:

```bash
sh ./scripts/setup-gke.sh
```

This script will:

- Run Terraform
    - This will be a no-op if you've already run it, but we need to get the output variables.
- Replace tokens in all config files in the `gke` folder with the real values that Terraform outputs.
- Run Skaffold to install Kueue
- Run Skaffold for basic configuration
- Run Skaffold to configure Kueue
