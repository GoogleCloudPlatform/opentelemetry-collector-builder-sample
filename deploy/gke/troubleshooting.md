## Troubleshooting deployment on GKE

### Cluster running but not seeing metrics on Google Cloud Console

If your cluster deployment is working fine, meaning all your pods are in a running state and `kubectl describe` does not show any issues, you can try running un `kubectl logs <pod_name> -n $OTEL_NAMESPACE` to figure out the exact cause for telemetry data not being exported to Google Cloud. 

Running this command will also show you if the telemetry data is being printed locally within the pod container. If not, then there might be an issue with the OpenTelemetry Collector configuration. This is likely if you udpated/modified the collector configuration. 

If the telemetry data is being printed locally, then most likely it is a permissions issue. You can verify this by looking at the errors within the logs. If this is the case, try following the steps mentioned in the below section - [Permission errors exporting telemetry](#permission-errors-exporting-telemetry).

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
export GCLOUD_PROJECT=<the Google Cloud project ID to which your IAM service account belongs>
export PROJECT_ID=<your Google Cloud project ID>
gcloud iam service-accounts create otel-collector --project=${GCLOUD_PROJECT}
```

**NOTE:** *If your GKE cluster and your service account are created in the same GCP project, then `GCLOUD_PROJECT` & `PROJECT_ID` will be the same.*

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

In the above,
- GSA_NAME: the name of your IAM service account.
- GSA_PROJECT: this is the GCP project to which the IAM service account belongs.

Essetially, `iam.gke.io/gcp-service-account` should contain the email of the service account you created using `gcloud iam service-accounts create` command in the beginning.

*Note that most of the steps in the above link to GCP documentation, like **creating a new namespace** would have already been done as part of running this sample (We will be using the same `$OTEL_NAMESPACE`).*

Following this, the collector pod will need to be restarted to take advantage of the new permissions.
You can do this by simply deleting it with `kubectl delete pod/otel-collector-<POD_NAME> -n $OTEL_NAMESPACE`.

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
    --member=serviceAccount:123456789123-compute@developer.gserviceaccount.com \
    --role="roles/artifactregistry.reader"
```
NOTE: If you followed the **default values** in this sample and are using Artifact Registry, `gcr.io` should be replaced with `otel-collectors` *(name of the repository)* and `us` would be `us-central1` *(location of the repository)*.

### Verify updates to files/ConfigMaps in Kubernetes cluster 

If you made an update to the Kubernetes ConfigMap and want to verify if the map is updated, you can run - 

```
kubectl describe <ConfigMap> -n $OTEL_NAMESPACE
```
*In case you have a different namespace, replace $OTEL_NAMESPACE with the name of that namespace.*

If you wish to verify that the file from which the map is created, is updated within the Kubernetes environment after updating the file locally and updating ConfigMap, you would need to get access to the shell of the running pod. 

Docker images for the examples in this repository are extemely minimal and do not contain the bash shell by default. To access the running pod's shell you would need to add these utilities to the Docker image of the OpenTelemetry Collector that you build & deploy. 

You would need the `sh` utility to access shell and `cat` utility - to view the contents of the file and to know if the file exists. 
Update the Dockerfile for the OpenTelemetry Collector image by adding the following lines - 

```
FROM busybox:1.35.0-uclibc as busybox
COPY --from=busybox /bin/sh /bin/sh   # copies the sh utility from busybox and puts it on /bin/sh
COPY --from=busybox /bin/cat /bin/cat # copies the cat utility from busybox and puts it on /bin/cat
``` 

Now the image built from this updated Dockerfile will have a shell access and the `cat` command available *(Simply installing the `sh` shell does not install all commands that typically come with the bash shell).* 
If you need more linux commands like `ls`, `mkdir`, etc. for debugging purposes, you can copy them from busybox in similar fashion. 

After building the image by following the same steps in `build/local` or `build/cloudbuild`, you need to redeploy the image to you GKE cluster using `kubectl apply -f manifest.yaml -n $OTEL_NAMESPACE`. 

To get shell access for the pod, run - 
```
kubectl exec -n $OTEL_NAMESPACE -it pod_container_name -- sh
```

To check the contents of a mounted file, run - 
```
kubectl exec -n $OTEL_NAMESPACE -it pod_container_name -- cat file_mount_path
```
In the above, 
 - `pod_container_name` is the name of the running pod. You can get the pod name using - `kubectl get pods -n $OTEL_NAMESPACE`.
 - `file_mount_path` is the path you configured in Kubernetes deployment in the `volumeMounts` section, for instance, for the redaction sample, this would be - `/mnt/testdata`. 
