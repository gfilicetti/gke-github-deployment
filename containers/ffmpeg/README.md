# FFmpeg Container

This is an example [ffmpeg](https://en.wikipedia.org/wiki/FFmpeg) container that is used to process each video file. This is described in the [Event-Driven FFmpeg Transcoding]( https://medium.com/google-cloud/event-driven-ffmpeg-transcoding-a-modern-solution-with-gcp-42995d5c3dbb) by Federico Iezzi. This is a very simple one-step transcoding example. Most use cases will have many steps and optimizations (CPUs, GPUs, etc).

Additionally, the [Intel Optimized FFmpeg](https://hub.docker.com/r/intel/intel-optimized-ffmpeg) container image can be referenced for more detail.

## Entrypoint

As an example, [entrypoint.sh](entrypoint.sh) is used to reference the command-line variable `MEDIA`, mount the `/input` and `/output` drives, and kick off the `ffmpeg` command.

## Build, Test and Deploy Locally

### Build the container

[Dockerfile](Dockerfile) extends the `intel/intel-optimized-ffmpeg:avx2` container.

```bash
docker build -t ffmpeg-container-name:v1 .
```

### Test Locally

```bash
docker run ffmpeg-container-name:v1 ffmpeg -v
```

### Deploy to Artifact Repository

1. Create a repository

2. Add a tag
    ```bash
    docker tag ffmpeg-container-name:v1 us-central1-docker.pkg.dev/alanpoole-transcoding-on-gke/intel-optimized-ffmpeg-avx2/ffmpeg-container-name:v1
    ```

3. Push
    ```bash
    docker push us-central1-docker.pkg.dev/alanpoole-transcoding-on-gke/intel-optimized-ffmpeg-avx2/ffmpeg-container-name:v1
    ```

## Build, Test and Deploy with Cloud Build

We have provided `cloudbuild.yaml` configuration file that will allow you to do the docker build on Google Cloud and have it automatically push to Artifact Registry.

Run this `gcloud` command:

```bash
gcloud builds submit --config ./cloudbuild.yaml \
--region us-central1 \
--substitutions _PROJECT_ID=$PROJECT_ID
```

## Use It in a Job

```
ffmpeg-container-name --MEDIA="filename.mp4"
```

Reads from `/input` (a local disk, a Google Cloud Storage Bucket, etc) and outputs the results to `/output`.


