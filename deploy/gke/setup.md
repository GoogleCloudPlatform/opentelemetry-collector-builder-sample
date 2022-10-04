
## Setup

* A built and pushed collector container image.  See [Building a Collector Image Locally](../../build/local/README.md) for instructions for a local build.
* A GCP project with billing enabled.
* A running GKE cluster
    - GKE offers 2 kinds of clusters - [Autopilot](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster) and [Standard](https://cloud.google.com/kubernetes-engine/docs/concepts/regional-clusters). These sample should work with both kinds of clusters. 
    - After creating the clusters, you will have to connect your local command line to the created cluster in order to interact with it. The steps to do this are available on your cloud console. 
        - On Google Cloud Console, locate & click the cluster you just created, on the resulting details page, there will be a `Connect` button on the top of the page containing the instructions to configure the cluster for local command line access. *(You should have `kubectl` installed for this)*
* Artifact Registry API enabled in your GCP project.
* Cloud Metrics, Cloud Trace, and/or Cloud Logging APIs enabled (optional depending on exporters configured in your collector).

Note that you may also need to configure certain GCP service account permissions.
