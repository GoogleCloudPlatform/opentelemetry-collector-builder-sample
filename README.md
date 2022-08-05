# OpenTelemetry Collector Builder sample

This repository holds a sample for using the [OpenTelemetry Collector Builder](https://github.com/open-telemetry/opentelemetry-collector-builder)

# Using this repo

## Building a collector

To build a custom collector with this repo, first edit [`builder-config.yaml`](builder-config.yaml) to set which
exporters and receivers to build into the collector.

Then to build a local collector binary run:
```
make build
```

Or build a docker image with:

```
make docker-build
```

## Building with Cloud Build and Artifact Registry

This repo also contains the commands necessary to build a collector using
[Cloud Build](https://cloud.google.com/build) and publish the container image
in [Artifact Registry](https://cloud.google.com/artifact-registry).

First, set up a container registry with:
```
make cloudbuild-setup
```

Then build and push the custom collector image to that registry with:
```
make cloudbuild
```

The Cloud Build steps are defined in [`cloudbuild.yaml`](cloudbuild.yaml).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.
