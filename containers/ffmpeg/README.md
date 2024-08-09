# FFmpeg Container

This is an example [ffmpeg](https://en.wikipedia.org/wiki/FFmpeg) container that is used to process each video file. This is described in the [Event-Driven FFmpeg Transcoding]( https://medium.com/google-cloud/event-driven-ffmpeg-transcoding-a-modern-solution-with-gcp-42995d5c3dbb) by Federico Iezzi. This is a very simple one-step transcoding example. Most use cases will have many steps and optimizations (CPUs, GPUs, etc).

Additinally, https://hub.docker.com/r/intel/intel-optimized-ffmpeg can be referenced for more detail.

## Setup Entrypoint

As an example, [entrypoint.sh](entrypoint.sh) is used to reference the command-line variable `MEDIA`, mount the `/input` and `/output` drives, and kick off the `ffmpeg` command.

## Build the container

[Dockerfile](Dockerfile) extends the `intel/intel-optimized-ffmpeg:avx2` container.

```
docker build -t ffmpeg-container-name:v1 .
```

## Test locally

```
docker run ffmpeg-container-name:v1 ffmpeg -v
```

## Deploy to Artifact Repository

1. Create a repository

2. Add a tag
```
docker tag ffmpeg-container-name:v1 us-central1-docker.pkg.dev/alanpoole-transcoding-on-gke/intel-optimized-ffmpeg-avx2/ffmpeg-container-name:v1
```

3. Push
```
docker push us-central1-docker.pkg.dev/alanpoole-transcoding-on-gke/intel-optimized-ffmpeg-avx2/ffmpeg-container-name:v1
```

## Use in a job

```
ffmpeg-container-name --MEDIA="filename.mp4"
```

Reads from `/input` (a local disk, a Google Cloud Storage Bucket, etc) and outputs the results to `/output`.