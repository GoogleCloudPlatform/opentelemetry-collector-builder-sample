

# Table of Contents
* [Building with Cloud Build](#Building-with-Cloud-Build)
	* [Prerequisite: Setup Artifact Registry](#Prerequisite:-Setup-Artifact-Registry)
	* [Build the Container Image with Cloud Build](#Build-the-Container-Image-with-Cloud-Build)

## Building with Cloud Build

This repo also contains the commands necessary to build a collector using
[Cloud Build](https://cloud.google.com/build) and publish the container image
in [Artifact Registry](https://cloud.google.com/artifact-registry).

### Prerequisite: Setup Artifact Registry

First, set up a container registry with:
```
make setup-artifact-registry
```

### Build the Container Image with Cloud Build

(This command makes use of environment variables defined in the [Makefile](../../Makefile) to name
the new registry).

Then build and push the custom collector image to that registry with:
```
make cloudbuild
```

The Cloud Build steps are defined in [`cloudbuild.yaml`](cloudbuild.yaml).