# Using Kueue k8s-native job Queuing

## Why [Kueue](https://kueue.sigs.k8s.io/docs/overview/)?

You can install Kueue on top of a vanilla Kubernetes cluster. Kueue does not replace any existing Kubernetes components. Kueue is compatible with cloud environments where:

Kueue APIs allow you to express:

Quotas and policies for fair sharing among tenants.
Resource fungibility: if a resource flavor is fully utilized, Kueue can admit the job using a different flavor.

Built-in support for popular jobs, e.g. BatchJob, Kubeflow training jobs, RayJob, RayCluster, JobSet, plain Pod.

## Prerequisites

1. Create a your GKE cluster
1. Get the credentials

## [Install Kueue](https://cloud.google.com/kubernetes-engine/docs/tutorials/kueue-intro)

```
VERSION=v0.8.0
kubectl apply --server-side -f \
  https://github.com/kubernetes-sigs/kueue/releases/download/$VERSION/manifests.yaml
```

* Replace VERSION with the latest version of Kueue. For more information about Kueue versions, see [Kueue releases](https://github.com/kubernetes-sigs/kueue/releases).

Wait for kueue-controller change the status to `Running`.

```
kubectl -n kueue-system get pods
```


## Create a batch job

Using the prebuilt [ffmpeg-container](../ffmpeg-container/README.md), published to Artifact Repository, kick off a new batch job in `us-central1-a` with the following configuration. Pass in the name the `-intput` video file as a variable `MEDIA=Big Buck Bunny Demo.mp4` to the container.

```
gcloud alpha batch jobs submit job-lza70prz --location us-central1 --network "https://www.googleapis.com/compute/v1/projects/alanpoole-transcoding-on-gke/global/networks/default-vpc" --subnetwork "https://www.googleapis.com/compute/v1/projects/alanpoole-transcoding-on-gke/regions/us-central1/subnetworks/default-vpc" --no-external-ip-address --config - <<EOD
{
  "taskGroups": [
    {
      "serviceAccount": {
        "email": "141244229955-compute@developer.gserviceaccount.com",
        "scopes": "https://www.googleapis.com/auth/cloud-platform"
      },
      "taskCount": "1",
      "parallelism": "1",
      "taskSpec": {
        "computeResource": {
            "cpuMilli": "16000",
            "memoryMib": "65536"
        },
        "runnables": [
          {
            "container": {
              "imageUri": "us-central1-docker.pkg.dev/alanpoole-transcoding-on-gke/intel-optimized-ffmpeg-avx2/ffmpeg-container-name:latest",
              "entrypoint": "",
              "volumes": [
                "/mnt/disks/input:/input",
                "/mnt/disks/output:/output"
              ]
            },
            "environment": {
              "variables": {
                "MEDIA": "Big Buck Bunny Demo.mp4"
              }
            }
          }
        ],
        "volumes": [
          {
            "gcs": {
              "remotePath": "alanpoole-transcoding-on-gke-input"
            },
            "mountPath": "/mnt/disks/input"
          },
          {
            "gcs": {
              "remotePath": "alanpoole-transcoding-on-gke-output"
            },
            "mountPath": "/mnt/disks/output"
          }
        ]
      }
    }
  ],
  "allocationPolicy": {
    "instances": [
      {
        "policy": {
          "provisioningModel": "SPOT",
          "machineType": "c2-standard-16"
        }
      }
    ],
    "location": {
      "allowedLocations": [
        "zones/us-central1-a"
      ]
    }
  },
  "logsPolicy": {
    "destination": "CLOUD_LOGGING"
  }
}
EOD
```

## Event-based triggers

Follow the instructions on [event-driven-ffmpeg-transcoding](https://medium.com/google-cloud/event-driven-ffmpeg-transcoding-a-modern-solution-with-gcp-42995d5c3dbb) to setup event-based triggers on the Cloud Storage Bucket `-input` to kick off the Batch Job when a user adds a new video file.