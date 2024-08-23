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

## Installation

[Install Kueue](https://cloud.google.com/kubernetes-engine/docs/tutorials/kueue-intro)

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

## Demo

### Configuration

Files (k8s manifests) to apply

| File Name | Description | Changes required | Command Line |
|---|---|---|---|
| [jobs-namespace-sa.yaml](./jobs-namespace-sa.yaml) | Create NS and SA. | SA and PROJECT_ID | `kubectl apply -f jobs-namespace-sa.yaml` |
| [cluster-queue.yaml](./cluster-queue.yaml) | Cluster queue and resource quota. |  | `kubectl apply -f cluster-queue.yaml` |
| [local-queue.yaml](./local-queue.yaml) | Local queue for different teams. |  | `kubectl apply -f local-queue.yaml` |
| [resource-flavor.yaml](./resource-flavor.yaml) | Configure resource flavor. |  | `kubectl apply -f resource-flavor.yaml` |
| [job-priority.yaml](./job-priority.yaml) | Configure workload priority. |  | `kubectl apply -f job-priority.yaml` |

### Submitting a simple job

Create a job for testing

```
kubectl create -f job-kueue-example-1.yaml
```

For status output, use

```
kubectl -n jobs get localqueues,clusterqueue,jobs,workloads
```

Use this to get status of the resource allocation

```
kubectl -n jobs get clusterqueue cluster-queue-a -o yaml
```


### Working with [Backoff limit per index](https://kubernetes.io/docs/concepts/workloads/controllers/job/#backoff-limit-per-index)

When you run an [indexed](https://kubernetes.io/docs/concepts/workloads/controllers/job/#completion-mode) Job, you can choose to handle retries for pod failures independently for each index. To do so, set the .spec.backoffLimitPerIndex to specify the maximal number of pod failures per index.

```
kubectl create -f job-kueue-example-2.yaml
```

### [Workload Priority Class](https://kueue.sigs.k8s.io/docs/concepts/workload_priority_class/) 

Let's start 10 replicas of the last job to see that we will have pending workloads when looking at the `clusterqueue` or `localqueues`, because we don't have enough resources to run (only 10Gi Memory)

```
for i in {1..10}; do kubectl create -f job-kueue-example-2.yaml; done
```

Create a new job with high priority and observe that this job will be admitted as soon as possible

```
kubectl create -f job-kueue-example-1.yaml
```

For status output, use

```
kubectl -n jobs get localqueues,clusterqueue,jobs,workloads,pods
```

### Sharing Resources [Cohort](https://kueue.sigs.k8s.io/docs/concepts/cluster_queue/#cohort)

1. Go to the [cluster-queue.yaml](./cluster-queue.yaml) file and enable the cohort "team-ab"
   1. Remove the `#` from this line `# cohort: "team-ab"`
   2. Repeat that for the cluster-queue-a and cluster-queue-b
   3. Apply the cluster-queue.yaml
   4. `kubectl get clusterqueue` to see the cohort creation
2. Run again 10 replicas of the last job, you can see that we borrowed resources from cluster-queue-b

```
for i in {1..10}; do kubectl create -f job-kueue-example-2.yaml; done
```

Take another look at the [cluster-queue.yaml](./cluster-queue.yaml), we can also use extra paramenters like `borrowingLimit` and `lendingLimit` to have more control of reosource allocation.

## Cleanup

Delete k8s resources

```
kubectl delete -f local-queue.yaml
kubectl delete -f cluster-queue.yaml
kubectl delete -f resource-flavor.yaml
```

Uninstall Kueue

```
VERSION=v0.8.0
kubectl delete -f \
  https://github.com/kubernetes-sigs/kueue/releases/download/$VERSION/manifests.yaml
```
