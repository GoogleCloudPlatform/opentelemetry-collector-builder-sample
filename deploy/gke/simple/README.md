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

The [troubleshooting](../troubleshooting.md) guide for more information on some of the most common issues such as authentication related issues. 

### Expected Outcome after running this sample

After a successful deployment of this sample, what we have is a GKE cluster on which we have a OpenTelemetry collector running. The collector is configured using the [otel-config](./otel-config.yaml) file. 

Since there is no application currently running on the cluster, the collector is not recieving any telemetry data. The current configuration in the [otel-config](./otel-config.yaml) file does however, scrape the collector itself for some metrics *(See the `prometheus/self` declared under `receivers`)* and exports these to stdout and google cloud. 

 - To check for metrics being exported to stdout, run `kubectl logs <pod_name> -n $OTEL_NAMESPACE`.
 - To check for metrics being exported to google cloud, open Metrics Explorer in Google Cloud Console. 

 There are many metrics that are emitted from the OpenTelemetry collector itself and most of these metrics start with the prefix `Otelcol` and you can search for this string in metrics explorer. 

*NOTE: You can chnage the configuration for the OpenTelemetry Collector to alter its behaviour.*

In case you are not seeing the expected outcome or are running into errors, look at the [troubleshooting](../troubleshooting.md) guide for more information.

## Try it out yourself (Optional)

Thus far, we've set up an OpenTelemetry collector configured to scrape itself and send metrics to the configured exporters. In this section we will introduce external source(s) of telemetry data to see how the collector operates on these sources. The sources will include data representing metrics, logs and traces.

You should be able to follow all steps mentioned in this README till [Verify the Deployment](#verify-the-deployment) successfully. This ensures that there are no permissions issues and you are able to succeesfully run a GKE cluster and connect to it.  

### Source of telemetry data

The example uses JSON file(s) containing telemetry data in OTLP format as source of telemetry data. These files can contain metrics, traces or logs - but each file should contain only a single type of telemetry data. Sample files have been provided in the folder - [otlp-data](./otlp-data/). The collector running in the cluster will then read these files and treat the data in them as if it were coming from a running application. 

### Updating the collector configuration to receive data from JSON file

We need to update the collector configuration file - [otel-config](./otel-config.yaml) to add a reciever that is able to receive telemetry data from the added JSON file.

Under the `receivers` section in the config file, add the following configuration - 

```
  otlpjsonfile:
    start_at: "beginning"
    include:
      - "/mnt/testdata/metrics/*.json"
      - "/mnt/testdata/traces/*.json"
      - "/mnt/testdata/logs/*.json"
```
For more details about this particular receiver, check [otlpjsonfilereceiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/otlpjsonfilereceiver).

***NOTE:** The path in `include` points to where the file would be mounted within the Kubernetes cluster environment and is therefore different from where it is present on your local machine. More information on this in [the next section](#making-the-json-file-available-within-the-cluster).*

Next, add this receiver in the traces pipeline, so your trace pipeline looks like - 

```
  traces:
    receivers: [otlp, otlpjsonfile]
    processors: [memory_limiter, batch, resourcedetection/gke]
    exporters: [googlecloud, logging]

  metrics:
    receivers: [otlp, prometheus/self, otlpjsonfile]
    processors: [memory_limiter, batch, resourcedetection/gke]
    exporters: [googlecloud, logging]
  
  logs:
    receivers: [otlp, otlpjsonfile]
    processors: [memory_limiter, batch, resourcedetection/gke]
    exporters: [googlecloud, logging]
```

For exporting logs to Google Cloud Platform, we need to further configure the collector with the log name and the GCP project ID. The project ID is used by the cloud exporter to create GCP log entries. 
Add the following configuration to the `googlecloud` exporter - 

```
  googlecloud:
    project: otel-test # Replace this with your Google Cloud Project ID
    retry_on_failure:
      enabled: false
    log:
      default_log_name: otel-collector-builder-sample/gke-simple-demo # This could be anything
```
***NOTE:** If you are unsure about where exactly these snippets should be placed in the collector config file, checkout [otel-config-sample.yaml](./otel-config-sample.yaml) for reference.*

### Making the JSON file available within the cluster 

Simply adding the JSON files within the directory does not grant the running cluster the access to these files. In order to get access to these files within the Kubernetes environment, we will be mounting them as a Kubernetes `ConfigMap`s for a new deployment - 

1. Make sure that there are no current deployments by running `kubectl get deployments -n $OTEL_NAMESPACE`. If there are active deployments, delete them using `kubectl delete`. 
2. Since we also updated our collector configuration, we will need to recreate the `otel-config` ConfigMap too. Delete the old ConfigMaps, if any before proceeding. 
    - To delete ConfigMaps, you can use `kubectl delete configmaps <ConfigMap name> -n $OTEL_NAMESPACE`. 
3. Recreate `otel-config` ConfigMap with the updated configuration - 
    ```
    kubectl create configmap otel-config --from-file=./otel-config.yaml -n $OTEL_NAMESPACE 
    ```
4. Create new ConfigMaps - one for each kind of telemetry data. These will be used to mount our test data in Kubernetes cluster as volumes - 
    - For metrics, create ConfigMap named `otlp-test-data-metrics` -  
        ```
        kubectl create configmap otlp-test-data-metrics --from-file=./otlp-data/testdata-metrics.json -n $OTEL_NAMESPACE
        ```
    - For traces, create ConfigMap named `otlp-test-data-traces` -  
        ```
        kubectl create configmap otlp-test-data-traces --from-file=./otlp-data/testdata-traces.json -n $OTEL_NAMESPACE
        ```
    - For logs, create ConfigMap named `otlp-test-data-logs` -  
        ```
        kubectl create configmap otlp-test-data-logs --from-file=./otlp-data/testdata-logs.json -n $OTEL_NAMESPACE
        ```
5. Update the [manifest.yaml](./manifest.yaml) to add `volume` and `volumeMount` configurations for the newly created ConfigMaps.
    - Update the `spec.volumes` section to add a new `configMap` entries
        ```
        volumes:
          - configMap:
              name: otel-config
            name: otel-collector-config-vol
          # Add the following volume configurations
          - configMap:
              name: otlp-test-data-metrics # Volume for test metrics data
            name: test-data-vol-metrics    # This could be changed to anything
          - configMap:
              name: otlp-test-data-traces # Volume for test traces data
            name: test-data-vol-traces    # This could be changed to anything
          - configMap:
              name: otlp-test-data-logs   # Volume for test logs data
            name: test-data-vol-logs      # This could be changed to anything
        ```  
    - Update the `spec.containers.volumeMounts` section to configure new volumeMount(s) for the added volumes.
        ```
        volumeMounts:
        - name: otel-collector-config-vol
          mountPath: /conf
        # Add the following volumeMount configurations
        - name: test-data-vol-metrics  # This name should match to the name of volume in spec.volumes
          mountPath: /mnt/testdata/metrics   # This is the location in the kubernetes environment where the file for configMap for metrics will be mounted
        - name: test-data-vol-traces  # This name should match to the name of volume in spec.volumes
          mountPath: /mnt/testdata/traces   # This is the location in the kubernetes environment where the file for configMap for traces will be mounted
        - name: test-data-vol-logs  # This name should match to the name of volume in spec.volumes
          mountPath: /mnt/testdata/logs   # This is the location in the kubernetes environment where the file for configMap for logs will be mounted
        ```
6. Deploy the cluster using the new deployment manifest - 
    ```
    kubectl apply -f manifest.yaml -n $OTEL_NAMESPACE
    ```
7. Verify if the telemetry data is now being emitted by using `kubectl logs` - 
    ```
    # Get the pod name(s)
    kubectl get pods -n $OTEL_NAMESPACE

    # Get the logs from a pod
    kubectl logs <pod_container_name> -n $OTEL_NAMESPACE
    ```

*If the logs do not show the expected telemetry data, check if the file used to send json data - [testdata.json](./otlp-data/testdata.json) is found in the Kubernetes deployment. Follow steps in [troubleshooting guide](../troubleshooting.md#verify-updates-to-filesconfigmaps-in-kubernetes-cluster) to verify file presence and contents.*

**NOTE: You will need to update the timestamps in [testdata-metrics](./otlp-data/testdata-metrics.json) to be within 24 hours of current time otherwise the metrics will not show up in Google Cloud console's Metrics Explorer. You might also need to update timestamps in other testdata - metrics and logs in case they become old enough to not be recognized by Google Cloud.**

### Seeing the telemetry data

At this point, we have several files acting as sources of telemetry data and a reciever configured withing the OpenTelemetry Collector that listens to these files whenever there are updates made to them. The collector also receives telemetry data from the files once when they are initially addedd (mounted).

So there should already be telemetry data emitted which should have been caught by the Collector. The current collector configuration has 2 exporters configured to where these traces will be exported -  
1. `googlecloud`
     - You can log into your Google Cloud console and then use [Trace List](https://console.cloud.google.com/traces/list) to look for traces, [Metrics Explorer](https://console.cloud.google.com/monitoring/metrics-explorer) or [Cloud Logging](https://console.cloud.google.com/logs) for logs.
 2. `logging` 
     - You can view the telemetry data on stdout for the pod container, run `kubectl logs <pod_container_name> -n $OTEL_NAMESPACE`. 

### Making a change to the telemetry data (Optional)

You might want to update the telemetry data being recieved by the collector to add new traces, metrics or logs or update any other attributes. To do this you need to make a change to the ConfigMap that is created from our test data file. To do this, you need to -
1. Update the telemetry data in the desired data file - [testdata-metrics.json](./otlp-data/testdata-metrics.json), [testdata-traces.json](./otlp-data/testdata-traces.json). Make sure that JSON here is **not** pretty printed and remains minified. 
2. Update the corresponding ConfigMap. For instance, if you made changes to `testdata-traces.json` file, you need to update `otlp-test-data-traces` - 
    ```
    kubectl create configmap otlp-test-data-traces --from-file=./otlp-data/testdata-traces.json -n $OTEL_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    ```

**NOTE**: It may take some time *(usually a few seconds)* for the config file to be updated.

To check if ConfigMap is updated, use following command with desired ConfigMap name - 
```
 kubectl describe configmaps otlp-test-data-traces -n $OTEL_NAMESPACE 
```

To check if the test file at mount path is updated, use following command with correct file path - 
```
 kubectl exec -n $OTEL_NAMESPACE -it  <pod_container_name> -- cat /mnt/testdata/traces/testdata-traces.json 
```

Once you see your changes are reflected in the file at mount path, you should notice that a new trace is recieved by the collector with the updated changes. 

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

```
kubectl delete namespace $OTEL_NAMESPACE
```
