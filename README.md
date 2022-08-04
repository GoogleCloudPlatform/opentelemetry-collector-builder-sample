# OpenTelemetry Collector Builder sample

This repository holds a sample for using the [OpenTelemetry Collector Builder](https://github.com/open-telemetry/opentelemetry-collector-builder)

# Using this repo

To build a custom collector with this repo, first edit `[builder-config.yaml](builder-config.yaml)` to set which
exporters and receivers to build into the collector.

Then to build a local collector binary run:
```
make build
```

Or build a docker image with:

```
make docker-build
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.
