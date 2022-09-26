
## Setup

* A built and pushed collector container image.  See [Building a Collector Image Locally](../../../build/local/) for instructions for a local build.
* A GCP project with billing enabled
* A running GKE cluster
* Artifact Registry enabled in your GCP project
* Cloud Metrics, Cloud Trace, and/or Cloud Logging APIs enabled (optional depending on exporters configured in your collector)

Note that you may also need to configure certain GCP service account permissions.