# OpenTelemetry Collector Builder sample

This repository holds a sample for using the [OpenTelemetry Collector Builder](https://github.com/open-telemetry/opentelemetry-collector-builder) configured with components generally useful for GCP deployments.

Table of Contents
=================

* [Using this repo](#using-this-repo)
* [Building a collector](#building-a-collector)
* [Building with Cloud Build and Artifact Registry](#building-with-cloud-build-and-artifact-registry)
* [Running on GKE](#running-on-gke)
   * [Prerequisites](#prerequisites)
   * [Set up namespace](#set-up-namespace)
   * [Create ConfigMap](#create-configmap)
   * [Build a container image](#build-a-container-image)
   * [(Optional) Cleanup](#optional-cleanup)
      * [Remove Kubernetes resources](#remove-kubernetes-resources)
   * [Troubleshooting](#troubleshooting)
      * [Permission errors exporting telemetry](#permission-errors-exporting-telemetry)
      * [ImagePullBackOff error when deploying collector](#imagepullbackoff-error-when-deploying-collector)
* [Contributing](#contributing)
* [License](#license)

# Using this repo

This repo is intended to be used as a sample demonstrating the full series of steps required to
build and deploy a custom OpenTelemetry Collector with GCP.

There are [public Docker images](https://hub.docker.com/r/otel/opentelemetry-collector-contrib/tags) available
for running the OpenTelemetry Collector, but these images can be [over 40MB](https://hub.docker.com/layers/otel/opentelemetry-collector-contrib/latest/images/sha256-fc00a2b722597af81f4335cfe15aa6ac76724f74b2f017ee24739cbcf5c39ec1?context=explore)
in size (and growing) and are packaged with [many components](https://github.com/open-telemetry/opentelemetry-collector-contrib)
which you may not need for your use case.

In contrast, a custom-built collector contains only the components you need, which can drastically shrink
its size (down to as small as a few MB) and provide security from extraneous compiled code. This repo
focuses on making it easy to build a GCP-specific collector with only those necessary components.

This repo is meant to be cloned, forked, or otherwise used within your own project. Feel free
to customize the [builder config](builder-config.yaml), [collector config](otel-config.yaml), or
[Cloud Build steps](cloudbuild.yml) to your needs. This repo provides a [Makefile](Makefile) that
automates many of the commands needed to interact with these files, which are described below.

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

Set `$GCLOUD_PROJECT` and `$CONTAINER_REGISTRY` to tag and push the resulting image.
Note: you will need an existing registry for this to work, that can be created with `make cloudbuild-setup` (below)

```
export GCLOUD_PROJECT=my-gcp-project
export CONTAINER_REGISTRY=custom-collectors
make docker-push
```

(If you get a permission error, you may need to run `gcloud auth configure-docker <your-registry-location>` to authenticate
Docker against your container registry).

You can customize these build steps by setting the following environment variables defined in the [Makefile](Makefile):

* `IMAGE_NAME` - name of the collector image, default: `otelcol-custom`
* `IMAGE_VERSION` - version of the collector image, default: `latest`
* `REGISTRY_LOCATION` - location of the registry to create/use with commands in this repo, default: `us-central1`
* `CONTAINER_REGISTRY` - name of the registry to hold collector images, default: `otel-collectors`

See "Artifact Registry" steps below for more info on setting up a container registry.

## Building with Cloud Build and Artifact Registry

This repo also contains the commands necessary to build a collector using
[Cloud Build](https://cloud.google.com/build) and publish the container image
in [Artifact Registry](https://cloud.google.com/artifact-registry).

First, set up a container registry with:
```
make cloudbuild-setup
```

(This command makes use of environment variables defined in the [Makefile](Makefile) to name
the new registry).

Then build and push the custom collector image to that registry with:
```
make cloudbuild
```

The Cloud Build steps are defined in [`cloudbuild.yaml`](cloudbuild.yaml).

## Running on GKE

### Prerequisites

* GCP project with billing enabled
* Running GKE cluster
* Artifact Registry enabled in your GCP project
* Cloud Metrics, Cloud Trace, and/or Cloud Logging APIs enabled (optional depending on exporters configured in your collector)

Note that you may also need to configure certain GCP service account permissions.
See the [Troubleshooting](#troubleshooting) section for more information if you encounter issues.

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

### Build a container image

If you did not do so already, run `make docker-build` to build a container image based on
the `builder-config.yaml` file in this repo (see [Building a collector](#building-a-collector)).
You can then run `make docker-push` to push the resulting image (note: you must set certain project and
registry environment variables for this push to work, as shown in that section).

Once the image is built, the file [`k8s/manifest.yaml`](k8s/manifest.yaml) will automatically be
updated to reference your image name. Create this manifest in your cluster with:

```
kubectl apply -f k8s/manifest.yaml -n $OTEL_NAMESPACE
```

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

#### Remove Kubernetes resources

```
kubectl delete -f k8s/manifest.yaml -n $OTEL_NAMESPACE

kubectl delete namespace $OTEL_NAMESPACE
```

### Troubleshooting

#### Permission errors exporting telemetry

If the collector pod fails to export metrics/logs/traces to GCP, it may need to be authorized
with the permissions to write to your project. One way to do this is with
[Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).

To set up Workload Identity, we are going to create a GCP service account and grant it
the roles to write logs, metrics, and traces. Then, we will bind the GCP service account
to the collector's Kubernetes ServiceAccount. Finally, we will annotate the Kubernetes ServiceAccount
to identify it as the Workload Identity account.

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

Bind the service account to the Kubernetes ServiceAccount:

```
gcloud iam service-accounts add-iam-policy-binding "otel-collector@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${GCLOUD_PROJECT}.svc.id.goog[otel-collector/otel-collector]"
```

Then follow the steps [in the GCP documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to) to
annotate the `otel-collector` ServiceAccount to work with Workload Identity. For example:

```
kubectl annotate serviceaccount otel-collector \
    --namespace $OTEL_NAMESPACE \
    iam.gke.io/gcp-service-account=GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com
```

Following this, the collector pod will need to be restarted to take advantage of the new permissions.
You can do this by simply deleting it with `kubectl delete pod/otel-collector-<POD_NAME>`.

##### (Cleanup) Remove gcloud service account and bindings
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

#### ImagePullBackOff error when deploying collector

If you are planning to build and host your collector image in Artifact Registry
(see [Building with Cloud Build and Artifact Registry](#building-with-cloud-build-and-artifact-registry)),
you may need to grant your GCP project's default service account with
[Artifact Registry reader permissions](https://cloud.google.com/kubernetes-engine/docs/troubleshooting#permission_denied_error).

Failure to do this can result in an `ImagePullBackOff` when trying to deploy the collector in GKE.

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

##### (Cleanup) Remove Artifact Registry permissions from default service account

(See steps for creating this permission to fill in command)
```
gcloud artifacts repositories remove-iam-policy-binding <REPOSITORY> \
    --location=<LOCATION> \
    --member=<YOUR_GCP_SA> \
    --role="roles/artifactregistry.reader"
```


## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.
