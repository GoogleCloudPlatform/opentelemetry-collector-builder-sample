## Redacting span attributes with the OpenTelemetry collector

This is a GKE-specific guide for using the collector's [redaction processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/redactionprocessor#redaction-processor). See the upstream documentation for the config reference.

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

### Create ConfigMaps

The [`otel-config.yaml`](otel-config.yaml) file contains a sample OpenTelemetry Collector config that is
prepopulated with some of the receivers, exporters, and processors included in this project. Edit it to
your desired [configuration](https://opentelemetry.io/docs/collector/configuration/) and create a ConfigMap
from it in the namespace you created above:

```
cd deploy/gke/redaction/
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

The [troubleshooting](../troubleshooting.md) guide for more information on some of the most common issues such as authentication related issues. 

### Expected Outcome after running this sample

After a successful deployment of this sample, what we have is a GKE cluster on which we have a OpenTelemetry collector running. The collector is configured using the [otel-config](./otel-config.yaml) file. 

Since there is no application currently running on the cluser, the collector does not recieve any telemetry data. Also, unlike the GKE sample in `simple` directory, the [otel-config](./otel-config.yaml) file for this sameple does not scrape the collector itself for any telemetry data. As a result, running this sample does not export any telemetry to stdout or Google Cloud.

Running `kubectl logs <pod_name> -n $OTEL_NAMESPACE`, you should see a message - `Everything is ready. Begin running and processing data.` indicating that the OpenTelemetry collector is up and running. 

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

```
kubectl delete namespace $OTEL_NAMESPACE
```