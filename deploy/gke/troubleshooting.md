## Troubleshooting deployment on GKE

### Permission errors exporting telemetry

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

#### (Cleanup) Remove gcloud service account and bindings
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

### ImagePullBackOff error when deploying collector

If you are planning to build and host your collector image in Artifact Registry
(see [Building with Cloud Build and Artifact Registry](../../build/cloudbuild/README.md#building-with-cloud-build-and-artifact-registry)),
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