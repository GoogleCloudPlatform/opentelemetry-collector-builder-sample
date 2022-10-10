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

## Try it out yourself (Optional)

Thus far, we've set up an OpenTelemetry collector configured with the redaction processor, but haven't sent it any telemetry data. In this section we will introduce a source of telemetry data to see the redaction processor in action.  

You should be able to follow all steps mentioned in this README up to [Verify the Deployment](#verify-the-deployment) successfully. This ensures that there are no permissions issues and you are able to successfully run a GKE cluster and connect to it. 

### Source of telemetry data

This example uses JSON files containing telemetry data in OTLP format as the source of telemetry data. A sample file has been provided here - [testdata.json](./otlp-data/testdata.json). The collector running in the cluster would read this file and treat the data in this file as if it is coming from a running application. 

### Updating the collector configuration to receive data from JSON file

Next, we would update our collector configuration file - [otel-config.yaml](./otel-config.yaml) to add a reciever that is able to receive telemetry data from the added JSON file. 

Under the `receivers` section in the config file, add the following configuration - 

```
  otlpjsonfile:
    start_at: "beginning"
    include:
      - "/mnt/testdata/*.json"
```
For more details about this particular receiver, check [otlpjsonfilereceiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/otlpjsonfilereceiver).

***NOTE:** The path in `include` points to where the file would be mounted within the Kubernetes cluster environment and is therefore different from where it is present on your local machine. More information on this in [the next section](#making-the-json-file-available-within-the-cluster).*

Next, add this receiver in the traces pipeline, so your trace pipeline looks like - 
```
 traces:
      receivers: [otlp, otlpjsonfile]
      processors: [memory_limiter, batch, resourcedetection/gke, redaction/credit_cards]
      exporters: [googlecloud, logging]
```
***NOTE:** If you are unsure about where exactly these snippets should be placed in the collector config file, checkout [otel-config-sample.yaml](./otel-config-sample.yaml) for reference.*
 
### Making the JSON file available within the cluster 

Simply adding the JSON file within the directory does not grant the running cluster the access to this file. In order to get access to this file within the Kubernetes environment, we would be mounting this file as a Kubernetes `ConfigMap` for a new deployment - 

1. Make sure that there are no current deployments by running `kubectl get deployments -n $OTEL_NAMESPACE`. If there are active deployments, delete them using `kubectl delete`. 
2. Since we also updated our collector configuration, we will need to recreate the `otel-config` ConfigMap too. Delete the old ConfigMaps, if any before proceeding. 
    - To delete ConfigMaps, you can use `kubectl delete configmaps <ConfigMap name> -n $OTEL_NAMESPACE`. 
3. Recreate `otel-config` ConfigMap with the updated configuration - 
    ```
    kubectl create configmap otel-config --from-file=./otel-config.yaml -n $OTEL_NAMESPACE
    ```
4. Create a new ConfigMap `otlp-test-data` - this will be used to mount our test data in the Kubernetes cluster as a volume - 
    ```
    kubectl create configmap otlp-test-data --from-file=./otlp-data/testdata.json -n $OTEL_NAMESPACE
    ``` 
5. Update the [manifest.yaml](./manifest.yaml) to add `volume` and `volumeMount` configuration for the newly created ConfigMap - `otlp-test-data`. 
   - Update the `spec.volumes` section to add a new `configMap` entry  
        ```
        volumes:
            - configMap:
                name: otel-config
              name: otel-collector-config-vol
            # Add the following new configMap entry
            - configMap:
                name: otlp-test-data
              name: test-data-vol   # This could be changed to anything
        ```
   - Update the `spec.containers.volumeMounts` section to configure a new volumeMount for the added volume. 
        ```
        volumeMounts:
        - name: otel-collector-config-vol
          mountPath: /conf
          # Add the following volumeMount 
        - name: test-data-vol  # This name should match to the name of volume in spec.volumes
          mountPath: /mnt/testdata  # This is the location in the Kubernetes environment where the file for ConfigMap will be mounted
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

### Seeing the redacted traces

At this point, we have a file acting as telemetry data source and a receiver configured within the OpenTelemetry Collector that listens to this file whenever an update to this is made. The collector also receives telemetry data from this file once when it is initially addedd (mounted). 

So there should already be a trace emitted which should have been caught by the Collector. The current collector configuration has 2 exporters configured to where these traces would be exported -  
 1. `googlecloud`
     - You can log into your Google Cloud console and then use [Trace List](https://console.cloud.google.com/traces/list) to look for traces. You can also search by trace ID which can be found in the sample data file - [testdata.json](./otlp-data/testdata.json). 
 2. `logging` 
     - You can view the trace data on stdout for the pod container, run `kubectl logs <pod_container_name> -n $OTEL_NAMESPACE`. 

In the outputs, notice the trace attribute - `credit.card.number`, you will notice that this data has been redacted - the actual card number is now replaced with `****` in traces. 

You can repeat the entire process described here with the `redaction/credit_cards` processor removed from the trace pipeline in [`otel-config`](./otel-config.yaml) and see that without this processor, the actual credit card numbers appear in traces. 

### Making a change to the telemetry data (Optional)

You might want to update the telemetry data being recieved by the collector to add new traces, update traceIDs or any other attributes. To do this you need to make a change to the ConfigMap that is created from our test data file. To do this, you need to -
1. Update the telemetry data in [testdata.json](./otlp-data/testdata.json). Make sure that JSON here is **not** pretty printed and remains minified. 
2. Update the `otlp-test-data` ConfigMap - 
    ```
    kubectl create configmap otlp-test-data --from-file=./otlp-data/testdata.json -n $OTEL_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    ```

**NOTE**: It may take some time *(usually a few seconds)* for the config file to be updated.

To check if ConfigMap is updated - 
```
 kubectl describe configmaps otlp-test-data -n $OTEL_NAMESPACE 
```

To check if the test file at mount path is updated - 
```
 kubectl exec -n $OTEL_NAMESPACE -it  <pod_container_name> -- cat /mnt/testdata/testdata.json 
```

Once you see your changes are reflected in the file at mount path, you should notice that a new trace is recieved by the collector with the updated changes. 

### (Optional) Cleanup

When you are done, you can clean up everything you've done with the following steps:

```
kubectl delete namespace $OTEL_NAMESPACE
```