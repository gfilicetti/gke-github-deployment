# FFmpeg API Container

For more information about the ffmpeg container at ffmpeg-api is built on, look at its [README](../ffmpeg/README.md).

## Variables for skaffold

```bash
export PROJECT_ID="testtest-431919"
export LOCATION="us-central1"
export SKAFFOLD_DEFAULT_REPO=${LOCATION:?}-docker.pkg.dev/${PROJECT_ID:?}/repo-batch-jobs
```

Change the BUCKETs for INPUT and OUTPUT on the file [k8s.yaml](./k8s.yaml)

Run skaffold

```bash
skaffold run
```

The skaffold will build a image of the ffmpeg-api and deploy 2 replicas of it (you can change to 1)

It will deploy a service called ffmpeg-api on the jobs namespace.

Get the External LoadBalancer IP

```bash
kubectl -n jobs get svc
```

Access the URL for the OpenAPI Specs

`http://<EXTERNAL_IP>/ffmpeg-api_docs`

You can use you `/ffmeg-api` for testing, just remember to upload the file to the INPUT BUCKET before it.


You can also use a command like this if desired

```bash
curl -X 'POST' <EXTERNAL_IP>/ffmpeg-api -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ "file": "<FILENAME_INSIDE_THE_INPUT_BUCKET>" }'
```

