## Building a Collector Binary locally

To build a local collector binary run:
```
cd build/local
make build
```

## Build a Collector Docker container locally 

### Prerequisite: Setup an Artifact Registry

To setup your artifact registry, run:
```
make setup-artifact-registry
```

### Build a Docker Container image locally

Build a docker image with:

```
make docker-build
```

### Push your Docker Container Image to the Artifact Registry

Set `$GCLOUD_PROJECT` and `$CONTAINER_REGISTRY` to tag and push the resulting image.
Note: you will need an existing registry for this to work, that can be created with ``.

```
export GCLOUD_PROJECT=my-gcp-project
export CONTAINER_REGISTRY=custom-collectors
make docker-push
```

(If you get a permission error, you may need to run `gcloud auth configure-docker <your-registry-location>` to authenticate
Docker against your container registry).

You can customize these build steps by setting the following environment variables defined in the [Makefile](../../Makefile):

* `IMAGE_NAME` - name of the collector image, default: `otelcol-custom`
* `IMAGE_VERSION` - version of the collector image, default: `latest`
* `REGISTRY_LOCATION` - location of the registry to create/use with commands in this repo, default: `us-central1`
* `CONTAINER_REGISTRY` - name of the registry to hold collector images, default: `otel-collectors`

## Adding collector Receivers, Processors, and Exporters

To cusomize your collector with this repo, first edit [`builder-config.yaml`](builder-config.yaml) to set which
exporters, receivers, and processors to build into the collector.  Then, run the steps above to (re-)build your
binary or container.