# GKE Setup and Configuration

In this section, we will setup and configure some things on GKE using by multiple components as well as what we need for individual components.

We will be using [Skaffold](https://skaffold.dev/docs/) to stand up the Kubernetes configuration.

## Configuring Common Components

If you haven't already, please make sure the infrastructure is setup already using Terraform. Instructions can be [found here](../terraform/README.md).

The Skaffold file for common components can be [found here](./common/skaffold.yaml).

## Configuring Kueue

For Kueue, we'll be doing two things, using Skaffold to install the framework itself and then using Skaffold to set up Kueue to our specs. 

## Setup script

Run this one script to setup everything:

```bash
./scripts/setup-gke.sh
```
