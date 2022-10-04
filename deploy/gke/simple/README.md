## Running a simple collector deployment on GKE

If this is the first example you are trying out, follow the [Setup](../setup.md) instructions to
complete the prerequisites.

**NOTE:** As a reminder, if you completed the pre-requisite steps successfully, the following requirements should have already been met - 
 - You should see the image name in [manifest.yaml](./manifest.yaml) updated with the fully qualified docker image name. 
 - The above mentioned docker image is actually uploaded to Artifact Registry and is visible there in cloud console.

If the above requirements are not met, please ensure that all the [Setup](../setup.md) instructions have been followed. You may need to perform a [local build](../../../build/local/README.md) again.

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
cd deploy/gke/simple/
kubectl create configmap otel-config --from-file=./otel-config.yaml -n $OTEL_NAMESPACE
```

### Create the Deployment

Create this manifest in your cluster with:

```
kubectl apply -f manifest.yaml -n $OTEL_NAMESPACE
```

### Verify the Deployment

After creating the deployment, you should verify that all pods created as part of the deployment are **running** - 

```
kubectl get deployments -n $OTEL_NAMESPACE
``` 

If the pods are not running, try using `kubectl describe` on the failing pods to get the exact cause for failure.

You can also use `kubectl logs` to check the logs of the failing pod containers to pinpoint the cause. 

The [Troubleshooting](../troubleshooting.md) guide for more information on some of the most common issues such as authentication related issues. 

### Expected Outcome after Running this Sample

After a successful deployment of this sample, what we have is a GKE cluster on which we have a OpenTelemetry collector running. The collector is configured using the [otel-config](./otel-config.yaml) file. 

Since there is no application currently running on the cluster, the collector is not recieving any telemetry data. The current configuration in the [otel-config](./otel-config.yaml) file does however, scrape the collector itself for some metrics *(See the `prometheus/self` declared under `receivers`)* and exports these to stdout and google cloud. 

 - To check for metrics being exported to stdout, run `kubectl logs <pod_name> -n $OTEL_NAMESPACE`.
 - To check for metrics being exported to google cloud, open Metrics Explorer in Google Cloud Console. 

 There are many metrics that are emitted from the OpenTelemetry collector itself and most of these metrics start with the prefix `Otelcol` and you can search for this string in metrics explorer. 

#### Potential Issues 
If you are not seeing metrics on Google Cloud, first run `kubectl logs <pod_name> -n $OTEL_NAMESPACE` to verify that they are being printed locally within the pod container and if any error/issue is being reported while exporting metrics to Google Cloud. 

Most likely, this issue is due to permission errors. Try following the troubleshooting steps mentioned here - [Permission errors exporting telemetry](../troubleshooting.md#permission-errors-exporting-telemetry).

*NOTE: You can chnage the configuration for the OpenTelemetry Collector to alter its behaviour.*

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

```
kubectl delete namespace $OTEL_NAMESPACE
```