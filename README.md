# OpenTelemetry Collector Builder sample

This repository holds a sample for using the [OpenTelemetry Collector Builder](https://github.com/open-telemetry/opentelemetry-collector-builder) configured with components generally useful for GCP deployments.

* [Building a collector](#building-a-collector)
* [Building with Cloud Build and Artifact Registry](#building-with-cloud-build-and-artifact-registry)
* [Running on GKE](#running-on-gke)

# Using this repo

## Building a collector

To build a custom collector with this repo, first edit [`builder-config.yaml`](builder-config.yaml) to set which
exporters and receivers to build into the collector.

Then to build a local collector binary run:
```
make build
```

Or build a docker image with:

```
make docker-build
```

## Building with Cloud Build and Artifact Registry

This repo also contains the commands necessary to build a collector using
[Cloud Build](https://cloud.google.com/build) and publish the container image
in [Artifact Registry](https://cloud.google.com/artifact-registry).

First, set up a container registry with:
```
make cloudbuild-setup
```

Then build and push the custom collector image to that registry with:
```
make cloudbuild
```

The Cloud Build steps are defined in [`cloudbuild.yaml`](cloudbuild.yaml).

## Running on GKE

### Prerequisites

* Running GKE cluster with [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) enabled

#### Setting up Workload Identity

If you don't already have one, create a GCP service account to authorize the collector to send metrics, traces, and logs:

```
export GCLOUD_PROJECT=<your GCP project>
export PROJECT_ID=<your Google Cloud project ID>
gcloud iam service-accounts create otel-collector --project=${GCLOUD_PROJECT}
```

Give the service account access to write metrics, traces, and logs (or more/fewer roles based on your config):

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role "roles/logging.logWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role "roles/cloudtrace.agent"
    
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role "roles/monitoring.metricWriter"
```

Bind the service account to a Kubernetes ServiceAccount (you'll create this Kubernetes ServiceAccount later
when you deploy the collector):

```
gcloud iam service-accounts add-iam-policy-binding "otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${GCLOUD_PROJECT}.svc.id.goog[otel-collector/otel-collector]"
```

#### Grant Artifact Registry permissions

If you are planning to build and host your collector image in Artifact Registry
(see [Building with Cloud Build and Artifact Registry](#building-with-cloud-build-and-artifact-registry)),
you will likely need to grant your GCP project's default service account with
[Artifact Registry reader permissions](https://cloud.google.com/kubernetes-engine/docs/troubleshooting#permission_denied_error).

Failure to do this may result in an `ImagePullBackOff` when trying to deploy the collector in GKE.

You can find the name of this service account with `gcloud iam service-accounts list`:

```
$ gcloud iam service-accounts list
DISPLAY NAME                            EMAIL                                                            DISABLED
Compute Engine default service account  123456789123-compute@developer.gserviceaccount.com               False
...
```

Give this service account reader permissions to the registry you plan to use for your collector images.
For example, if you are using `gcr.io` in `us` with the account from above:

```
gcloud artifacts repositories add-iam-policy-binding gcr.io \
    --location=us \
    --member=123456789123-compute@developer.gserviceaccount.com \
    --role="roles/artifactregistry.reader"
```

This concludes the prerequisites required to authenticate the OpenTelemetry collector to GCP
using Workload Identity. Next, follow the steps below to deploy the Kubernetes manifests.

### Set up namespace

Create a namespace in your cluster to run the collector:

```
export OTEL_NAMESPACE=otel-collector
kubectl create namespace $OTEL_NAMESPACE
```

### Apply Workload Identity permissions

Create the Kubernetes ServiceAccount that the collector will use to authenticate with GCP monitoring:

```
kubectl create sa otel-collector -n $OTEL_NAMESPACE
```

Then follow the steps [in the GCP documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to) to
annotate the `otel-collector` ServiceAccount to work with Workload Identity. For example:

```
kubectl annotate serviceaccount otel-collector \
    --namespace $OTEL_NAMESPACE \
    iam.gke.io/gcp-service-account=GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com
```

### Create ConfigMap

The [`otel-config.yaml`](otel-config.yaml) file contains a sample OpenTelemetry Collector config that is
prepopulated with some of the receivers, exporters, and processors included in this project. Edit it to
your desired [configuration](https://opentelemetry.io/docs/collector/configuration/) and create a ConfigMap
from it in the namespace you created above:

```
kubectl create configmap otel-config --from-file=./otel-config.yaml -n $OTEL_NAMESPACE
```

### Build a container image

If you did not do so already, run `make docker-build` to build a container image based on
the `builder-config.yaml` file in this repo (see [Building a collector](#building-a-collector)).
Note that you may have to run `docker push` to make this image available in your cluster.

Once the image is built, the file [`k8s/manifest.yaml`](k8s/manifest.yaml) will automatically be
updated to reference your image name. Create this manifest in your cluster with:

```
kubectl apply -f k8s/manifest.yaml -n $OTEL_NAMESPACE
```

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

#### Remove gcloud service account and bindings
```
gcloud iam service-accounts delete otel-collector --project=${GCLOUD_PROJECT}

gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role "roles/logging.logWriter"

gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role "roles/cloudtrace.agent"

gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role "roles/monitoring.metricWriter"

gcloud iam service-accounts remove-iam-policy-binding "otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${GCLOUD_PROJECT}.svc.id.goog[otel-collector/otel-collector]"
```

#### Remove Artifact Registry permissions from default service account

(See steps for creating this permission to fill in command)
```
gcloud artifacts repositories remove-iam-policy-binding <REPOSITORY> \
    --location=<LOCATION> \
    --member=<YOUR_GCP_SA> \
    --role="roles/artifactregistry.reader"
```

#### Remove Kubernetes resources

```
kubectl delete -f k8s/manifest.yaml -n $OTEL_NAMESPACE

kubectl delete namespace $OTEL_NAMESPACE
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.
