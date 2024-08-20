# Container Images

This folder holds source code and Docker configurations for the container images we'll be building and using:
- [ffmpeg](./ffmpeg/README.md)

## Building Container Images

This section describes the process for building and pushing container images to Artifact Registry, where they will later be used to deploy to a container runtime environment like GKE.

1. Navigate to the directory of the container image you are building (eg: the ffmpeg container image):

    ```bash
    cd ./containers/ffmpeg
    ```

2. Run this command to invoke Cloud Build and build and deploy your container image to Artifact Registry

    ```bash
    gcloud builds submit --config ./cloudbuild.yaml \
    --region us-central1 \
    --substitutions _PROJECT_ID=$PROJECT_ID
    ```
