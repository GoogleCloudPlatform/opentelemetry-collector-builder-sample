# OpenTelemetry Collector Builder sample

# Table of Contents
* [Using this repo](#Using-this-repo)
	* [Sample Recipes](#Sample-Recipes)
		* [Building your OpenTelemetry Collector](#Building-your-OpenTelemetry-Collector)
		* [Deploying your OpenTelemetry Collector](#Deploying-your-OpenTelemetry-Collector)
	* [Contributing](#Contributing)
	* [License](#License)


This repository holds a sample for using the [OpenTelemetry Collector Builder](https://github.com/open-telemetry/opentelemetry-collector-builder) configured with components generally useful for GCP deployments.

Table of Contents
=================

* [Using this repo](#using-this-repo)
* [Sample Recipes](#sample-recipes)
    * [Building your OpenTelemetry Collector](#building-your-opentelemetry-collector)
    * [Deploying your OpenTelemetry Collector](#deploying-your-opentelemetry-collector)
* [Contributing](#contributing)
* [License](#license)

# Using this repo

This repo is intended to be used as a sample demonstrating the full series of steps required to
build and deploy a custom OpenTelemetry Collector with GCP.

There are [public Docker images](https://hub.docker.com/r/otel/opentelemetry-collector-contrib/tags) available
for running the OpenTelemetry Collector, but these images can be [over 40MB](https://hub.docker.com/layers/otel/opentelemetry-collector-contrib/latest/images/sha256-fc00a2b722597af81f4335cfe15aa6ac76724f74b2f017ee24739cbcf5c39ec1?context=explore)
in size (and growing) and are packaged with [many components](https://github.com/open-telemetry/opentelemetry-collector-contrib)
which you may not need for your use case.

In contrast, a custom-built collector contains only the components you need, which can drastically shrink
its size (down to as small as a few MB) and provide security from extraneous compiled code. This repo
focuses on making it easy to build a GCP-specific collector with only those necessary components.

This repo is meant to be cloned, forked, or otherwise used within your own project. Feel free
to customize the [builder config](build/local/builder-config.yaml), [collector config](build/local/otel-config.yaml), or
[Cloud Build steps](build/cloudbuild/cloudbuild.yml) to your needs. This repo provides a [Makefile](Makefile) that
automates many of the commands needed to interact with these files, which are described below.

## Sample Recipes

### Building your OpenTelemetry Collector

* [Local collector builds](build/local/) - Build a Collector binary or docker image locally, and push to [Artifact Registry](https://cloud.google.com/artifact-registry)
* [Collector builds with Cloud Build](build/cloudbuild/) - Build the Collector on [Cloud Build](https://cloud.google.com/build): Google's hosted CI/CD platform

### Deploying your OpenTelemetry Collector

* [Simple GKE Deployment](deploy/gke/simple/) - Deploy a Kubernetes [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) with a simple collector that sends metrics, logs, and traces to GCP.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.