# Using Kueue k8s-native job Queuing

## Why [Kueue](https://kueue.sigs.k8s.io/docs/overview/)?

You can install Kueue on top of a vanilla Kubernetes cluster. Kueue does not replace any existing Kubernetes components. Kueue is compatible with cloud environments.

Kueue APIs allow you to express:
- Quotas and policies for fair sharing among tenants.
- Resource fungibility: if a resource flavor is fully utilized, Kueue can admit the job using a different flavor.

Kueue has built-in support for popular jobs:
- BatchJob
- Kubeflow training jobs
- RayJob
- RayCluster
- JobSet
- Plain Pod.

## Prerequisites

1. Create a your GKE cluster
  - This was done when you ran Terraform to provision your infrastructure.
2. Get the `kubectl` credentials
  - Run this `gcloud` command to setup your credentials:
  
    ```bash
    gcloud container clusters get-credentials gke-gcp-test --region us-central1
    ```

3. Install Kueue using [these instructions](../../README.md).

## Demo

### Configuration

Please apply all of these Kubernetes manifests using the command line given

| File Name | Description | Command Line |
|---|---|---|
| [jobs-namespace-sa.yaml](./jobs-namespace-sa.yaml) | Create NS and SA. | `kubectl apply -f jobs-namespace-sa.yaml` |
| [cluster-queue.yaml](./cluster-queue.yaml) | Cluster queue and resource quota. | `kubectl apply -f cluster-queue.yaml` |
| [local-queue.yaml](./local-queue.yaml) | Local queue for different teams. | `kubectl apply -f local-queue.yaml` |
| [resource-flavor.yaml](./resource-flavor.yaml) | Configure resource flavor. | `kubectl apply -f resource-flavor.yaml` |
| [job-priority.yaml](./job-priority.yaml) | Configure workload priority. | `kubectl apply -f job-priority.yaml` |

### Submitting a Simple Job

Create a job for testing:
```bash
kubectl create -f job-kueue-example-1.yaml
```

For status output, use:
```bash
kubectl -n jobs get localqueues,clusterqueue,jobs,workloads,pods
```

Use this command to get resource allocation status:
```bash
kubectl -n jobs get clusterqueue cluster-queue-a -o yaml
```

### Working with a [Backoff Limit Per Index](https://kubernetes.io/docs/concepts/workloads/controllers/job/#backoff-limit-per-index)

When you run an [indexed](https://kubernetes.io/docs/concepts/workloads/controllers/job/#completion-mode) Job, you can choose to handle retries for pod failures independently for each index. To do so, set the .spec.backoffLimitPerIndex to specify the maximal number of pod failures per index.

```bash
kubectl create -f job-kueue-example-2.yaml
```

### [Workload Priority Class](https://kueue.sigs.k8s.io/docs/concepts/workload_priority_class/) 

Let's start 10 replicas of the last job to get some pending workloads when looking at the `clusterqueue` or `localqueues`, because we don't have enough resources to run (we only have 10Gi):

```bash
for i in {1..10}; do kubectl create -f job-kueue-example-2.yaml; done
```

Create a new job with high priority and observe that this job will be admitted as soon as possible:
```bash
kubectl create -f job-kueue-example-1.yaml
```

For status output, use:
```bash
kubectl -n jobs get localqueues,clusterqueue,jobs,workloads,pods
```

### Sharing Resources With [Cohorts](https://kueue.sigs.k8s.io/docs/concepts/cluster_queue/#cohort)

1. Go to the [cluster-queue.yaml](./cluster-queue.yaml) file and enable the cohort "team-ab"
   1. Remove the `#` from this line `# cohort: "team-ab"`
   2. Repeat that for the `cluster-queue-a` and `cluster-queue-b`
   3. Apply the cluster-queue.yaml
   4. `kubectl get clusterqueue` to see the cohort creation
2. Once again, run 10 replicas of the last job. You can see that we borrowed resources from `cluster-queue-b`

  ```bash
  for i in {1..10}; do kubectl create -f job-kueue-example-2.yaml; done
  ```

Take another look at the [cluster-queue.yaml](./cluster-queue.yaml), we can also use extra parameters like `borrowingLimit` and `lendingLimit` to have more control over our resource allocation.

## Cleanup

Delete k8s resources:
```bash
kubectl delete -f local-queue.yaml
kubectl delete -f cluster-queue.yaml
kubectl delete -f resource-flavor.yaml
```

