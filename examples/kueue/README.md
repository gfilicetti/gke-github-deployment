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

## Files

| name | description | modules | resources |
|---|---|---|---|
| [jobs-namespace-sa.yaml](./jobs-namespace-sa.yaml) | Create NS and SA. |  | `kubectl apply -f jobs-namespace-sa.yaml` |
| [cluster-queue.yaml](./cluster-queue.yaml) | Cluster queue and resource quota. |  | `kubectl apply -f cluster-queue.yaml` |
| [local-queue.yaml](./local-queue.yaml) | Local queue for different teams. |  | `kubectl apply -f local-queue.yaml` |
| [resource-flavor.yaml](./resource-flavor.yaml) | Configure resource flavor. |  | `kubectl apply -f resource-flavor.yaml` |
| [kueue-job-fuse-test.yaml](./kueue-job-fuse-test.yaml) | Add a job in a queue. |  | `kubectl create -f kueue-job-fuse-test.yaml` |

You can create as many jobs as you want

```
kubectl create -f kueue-job-fuse-test.yaml
```

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
