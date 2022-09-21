## Running a simple collector deployment on GKE

### Prerequisites

* A built and pushed collector container image.  See [Building a Collector Image Locally](../../../build/local/) for instructions for a local build.
* A GCP project with billing enabled
* A running GKE cluster
* Artifact Registry enabled in your GCP project
* Cloud Metrics, Cloud Trace, and/or Cloud Logging APIs enabled (optional depending on exporters configured in your collector)

Note that you may also need to configure certain GCP service account permissions.
See the [Troubleshooting](../troubleshooting.md) guide for more information if you encounter issues.

### Set up namespace

Create a namespace in your cluster to run the collector:

```
export OTEL_NAMESPACE=otel-collector
kubectl create namespace $OTEL_NAMESPACE
```

### Create ConfigMap

The [`otel-config.yaml`](otel-config.yaml) file contains a sample OpenTelemetry Collector config that is
prepopulated with some of the receivers, exporters, and processors included in this project. Edit it to
your desired [configuration](https://opentelemetry.io/docs/collector/configuration/) and create a ConfigMap
from it in the namespace you created above:

```
kubectl create configmap otel-config --from-file=./otel-config.yaml -n $OTEL_NAMESPACE
```

### Create the Deployment

When you built your collector image, the file [`manifest.yaml`](manifest.yaml)
was automatically updated to reference your image name. Create this manifest in your cluster with:

```
cd deploy/gke/simple/
kubectl apply -f manifest.yaml -n $OTEL_NAMESPACE
```

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

#### Remove Kubernetes resources

```
kubectl delete -f manifest.yaml -n $OTEL_NAMESPACE

kubectl delete namespace $OTEL_NAMESPACE
```

##### (Cleanup) Remove Artifact Registry permissions from default service account

(See steps for creating this permission to fill in command)
```
gcloud artifacts repositories remove-iam-policy-binding <REPOSITORY> \
    --location=<LOCATION> \
    --member=<YOUR_GCP_SA> \
    --role="roles/artifactregistry.reader"
```