# Using Batch Compute Jobs

For one-time or routine batch processing, the [Compute Engine Batch](https://cloud.google.com/batch/docs/create-run-job) service can be used to define a job template, setup quota, schedule 1-N jobs, clean up, and monitor/troubleshoot jobs as they run.

Alternatively, this Quickstart guide: [Create and run an example job](https://cloud.google.com/batch/docs/create-run-example-job) can be followed. It makes use of a startup bash script. The example below uses a container to process the image.

## Prerequisites

1. Create a new GCP Project and ensure [Billing is enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#console) 
1. Create a `default-vpc` network and sub-networks
1. Create a Cloud NAT
1. Enable the [Batch API](https://console.cloud.google.com/flows/enableapi?apiid=batch.googleapis.com,compute.googleapis.com,logging.googleapis.com&_ga=2.202165972.418309743.1722610490-793002559.1722604502)
1. Ensure the [default compute service account](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account) is available for use, or [customize it with a new one](https://cloud.google.com/batch/docs/create-run-job-custom-service-account)

## Set quota

Open the Compute Engine API [quotas and system limits](https://console.cloud.google.com/apis/api/compute.googleapis.com/quotas) page. Filter by the region, zone, and hardware type. Set the appropriate maximum number of vCPUs (or other hardware) to allocate to the project.

Example: \
`name:C2 CPUs` and `Dimensions (e.g. location):us-central1`

## Create Cloud Storage Buckets

Create an `-input` and `-ouput` Cloud Storage bucket. Copy [4kmedia.org/big-buck-bunny-4k-demo](https://4kmedia.org/big-buck-bunny-4k-demo) video file into the `-intput`.

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