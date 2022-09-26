## Redacting span attributes with the OpenTelemetry collector

This is a GKE-specific guide for using the collector's [redaction processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/redactionprocessor#redaction-processor). See the upstream documentation for the config reference.

If this is the first example you are trying out, follow the [Setup](../setup.md) instructions to
complete the prerequisites.

See the [Troubleshooting](../troubleshooting.md) guide for more information if you encounter issues.

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

When you built your collector image, the file [`manifest.yaml`](manifest.yaml)
was automatically updated to reference your image name. Create this manifest in your cluster with:

```
kubectl apply -f manifest.yaml -n $OTEL_NAMESPACE
```

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

```
kubectl delete namespace $OTEL_NAMESPACE
```