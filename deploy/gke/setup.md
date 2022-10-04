
## Prerequisites
Running the GKE (Google Kubernetes Engine) samples in this repository assumes familiarity with the following - 
 - Creating GKE clusters on Google Cloud. 
 - Configuring command-line access to your cluster via kubectl. 

For more information on these, you can checkout [Create a GKE cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster) & [Configure cluster access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#gcloud_1).  
## Setup

* A built and pushed collector container image.  See [Building a Collector Image Locally](../../build/local/README.md) for instructions for a local build.
* A GCP project with billing enabled.
* A running GKE cluster with command line access configured.     
* Artifact Registry API enabled in your GCP project.
* Cloud Metrics, Cloud Trace, and/or Cloud Logging APIs enabled (optional depending on exporters configured in your collector).

Note that you may also need to configure certain GCP service account permissions.
