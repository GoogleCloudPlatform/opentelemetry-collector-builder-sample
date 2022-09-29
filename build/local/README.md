## Prerequisites 
Prior to following the instructions here, make sure of the following steps to ensure a smooth process - 
 - You should have `go` installed on your machine. You can find the installation instructions for your OS [here](https://go.dev/doc/install).
 - Make sure that you have [docker](https://docs.docker.com/engine/install/) installed on your machine.
    - Also verify that you are able to run docker commands without the need to gain root permissions using sudo. You can follow the [post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/) to achieve this.

## Building a Collector Binary locally

To build a local collector binary run:
```
cd build/local
make build
```

## Build a Collector Docker container locally 

At the end of these steps, you should have a docker image with the collector generated within the `bin` folder. 

### Prerequisite: Setup an Artifact Registry

To setup your artifact registry, run:
```
make setup-artifact-registry
```
This will create an artifact registry with the name `otel-collectors` within your selected Google Cloud project. The name can be changed by updating the `CONTAINER_REGISTRY` variable as explained [here](#customizable-settings).

*You can view the currently selected project by running `gcloud config get project` in a terminal.*

### Build a Docker Container image locally

Build a docker image with:

```
make docker-build
```

## Push your Docker Container Image to the [Artifact Registry](https://cloud.google.com/artifact-registry)

Note: you will need an existing registry for this to work, that was created as part of the [prequisites](#prerequisite-setup-an-artifact-registry).

```
make docker-push
```

#### NOTE:
 - If you get a permission error, you may need to run `gcloud auth configure-docker <your-artifact-registry>` to authenticate Docker against your artifact registry. 
 - Here, `<your-artifact-registry>` would look something like `us-central1-docker.pkg.dev` if your preferred location for your created registry was `us-central1`. 
    - You can get a list of valid locations by running `gcloud artifacts locations list`.
 - The preferred location can be modified by updating the Makefile ([explained below](#Customizable-settings)).
 - If you are unsure about what should be `<your-artifact-registry>`, you can also find the exact command to run from Google Cloud console. Navigate to the Artifact Registry product page within your selected project, select the artifact registry you created and click **Setup Instructions** button. The popup should have the exact  command that you need to run to authenticate docker. 

#### Customizable settings  

You can customize these build steps by setting the following environment variables defined in the [Makefile](../../Makefile):

* `IMAGE_NAME` - name of the collector image, default: `otelcol-custom`
* `IMAGE_VERSION` - version of the collector image, default: `latest`
* `REGISTRY_LOCATION` - location of the registry to create/use with commands in this repo, default: `us-central1`
* `CONTAINER_REGISTRY` - name of the registry to hold collector images, default: `otel-collectors`

## Adding collector Receivers, Processors, and Exporters

To cusomize your collector with this repo, first edit [`builder-config.yaml`](builder-config.yaml) to set which
exporters, receivers, and processors to build into the collector.  Then, run the steps above to (re-)build your
binary or container.