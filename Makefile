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

OUTPUT_DIR=bin
OTEL_VERSION=0.57.2

IMAGE_NAME=otelcol-custom
IMAGE_VERSION=latest

CONTAINER_REGISTRY=otel-collectors
REGISTRY_LOCATION=us-central1

.PHONY: setup
setup:
	go install go.opentelemetry.io/collector/cmd/builder@v${OTEL_VERSION}

.PHONY: build
build: setup
	mkdir -p ${OUTPUT_DIR}
	builder --config=builder-config.yaml --name=otelcol-custom --output-path=${OUTPUT_DIR}/.

.PHONY: docker-build
docker-build:
	docker build -t ${IMAGE_NAME}:${IMAGE_VERSION} .

.PHONY: cloudbuild-setup
cloudbuild-setup:
	gcloud artifacts repositories create ${CONTAINER_REGISTRY} --repository-format=docker --location=${REGISTRY_LOCATION} --description="Custom build OpenTelemetry collector container registry"

.PHONY: cloudbuild
cloudbuild:
	gcloud beta builds submit --substitutions=_COLLECTOR_REPO=${CONTAINER_REGISTRY},_COLLECTOR_IMAGE=${IMAGE_NAME}:${IMAGE_VERSION}
