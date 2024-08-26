# FFmpeg API Container

For more information about the FFmpeg, look to the original repo at [ffmpeg](../ffmpeg/)

## Variables for skaffold

```
export PROJECT_ID="testtest-431919"
export LOCATION="us-central1"
export SKAFFOLD_DEFAULT_REPO=${LOCATION:?}-docker.pkg.dev/${PROJECT_ID:?}/repo-batch-jobs
```

Change the BUCKETs for INPUT and OUTPUT on the file [k8s.yaml](./k8s.yaml)

Run skaffold

```
skaffold run
```

The skaffold will build a image of the ffmpeg-api and deploy 2 replicas of it (you can change to 1)

It will deploy a service called ffmpeg-api on the jobs namespace
Get the External Loadbalancer IP

```
kubectl -n jobs get svc
```

Access the URL for the OpenAPI Specs

http://<EXTERNAL_IP>/ffmpeg-api_docs


You can use you /ffmeg-api for testing, just remember to upload the file to the INPUT BUCKET before it.


You can also use a commando like this if desired

```
curl -X 'POST' <EXTERNAL_IP>/ffmpeg-api -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ "file": "<FILENAME_INSIDE_THE_INPUT_BUICKET>" }'
```

