# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include ../../Makefile

OUTPUT_DIR=bin
OTEL_VERSION=0.70.0
GCLOUD_PROJECT ?= $(shell gcloud config get project)

.PHONY: setup
setup:
	go install go.opentelemetry.io/collector/cmd/builder@v${OTEL_VERSION}

.PHONY: build
build: setup
	mkdir -p ${OUTPUT_DIR}
	builder --config=builder-config.yaml

.PHONY: docker-build
docker-build: setup
	docker build -t ${IMAGE_NAME}:${IMAGE_VERSION} .
	sed -i "s/%OTEL_COLLECTOR_IMAGE%/${REGISTRY_LOCATION}-docker.pkg.dev\/${GCLOUD_PROJECT}\/${CONTAINER_REGISTRY}\/${IMAGE_NAME}:${IMAGE_VERSION}/g" ../../deploy/gke/simple/manifest.yaml
	sed -i "s/%OTEL_COLLECTOR_IMAGE%/${REGISTRY_LOCATION}-docker.pkg.dev\/${GCLOUD_PROJECT}\/${CONTAINER_REGISTRY}\/${IMAGE_NAME}:${IMAGE_VERSION}/g" ../../deploy/gke/redaction/manifest.yaml

.PHONY: docker-push
docker-push:
	docker tag ${IMAGE_NAME}:${IMAGE_VERSION} ${REGISTRY_LOCATION}-docker.pkg.dev/${GCLOUD_PROJECT}/${CONTAINER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}
	docker push ${REGISTRY_LOCATION}-docker.pkg.dev/${GCLOUD_PROJECT}/${CONTAINER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}
