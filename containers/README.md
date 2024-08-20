# Containers

This folder holds source code and Docker configurations for the containers we'll be building and using:
- [ffmpeg](./ffmpeg/README.md)

## Building Containers

This section describes the process for building and pushing containers to Artifact Registry, where they will later be used to deploy to a container runtime environment like GKE.

1. Navigate to the directory of the container image you are building:

    ```bash
    cd ./containers/ffmpeg
    ```

2. Run this command to invoke Cloud Build and build and deploy your container to Artifact Registry

    ```bash
    gcloud builds submit --config ./cloudbuild.yaml \
    --region us-central1 \
    --substitutions _PROJECT_ID=$PROJECT_ID
    ```
