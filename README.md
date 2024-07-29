# gke-github-deployment
This repository is a full example of a CI/CD pipeline using Github actions, terraform and other tech to create and deploy workloads to a GKE Autopilot installation.

## Objectives
Creating a github actions workflow and deployment strategy for deploying new Autopilot clusters.
Creating a github actions workflow and deployment strategy for building a container and deploying it to an Autopilot cluster.

## Tech Used
- Github Actions
- terraform
- GKE Autopilot
- Artifact Registry
- (Helm charts)
- (ArgoCD)

## Workload
We will be deploying a container image of a customized 'ffmpeg' build to a GKE Autopilot Kubernetes cluster.

## Notes
- Due to the need for potentially 15k+ nodes, configuration and deployment of multiple Autopilot clusters must be supported.
