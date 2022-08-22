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
	curl -L -o ${OUTPUT_DIR}/ocb --create-dirs https://github.com/open-telemetry/opentelemetry-collector/releases/download/v${OTEL_VERSION}/ocb_${OTEL_VERSION}_linux_amd64
	chmod +x ${OUTPUT_DIR}/ocb


.PHONY: build
build: setup
	bin/ocb --config=builder-config.yaml --name=otelcol-custom --output-path=bin/.

.PHONY: docker-build
docker-build:
	docker build -t ${IMAGE_NAME}:${IMAGE_VERSION} .
	sed -i "s/%OTEL_COLLECTOR_IMAGE%/${IMAGE_NAME}:${IMAGE_VERSION}/g" k8s/manifest.yaml

.PHONY: docker-push
docker-push:
	docker tag ${IMAGE_NAME}:${IMAGE_VERSION} ${REGISTRY_LOCATION}-docker.pkg.dev/${GCLOUD_PROJECT}/${CONTAINER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}
	docker push ${REGISTRY_LOCATION}-docker.pkg.dev/${GCLOUD_PROJECT}/${CONTAINER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}

.PHONY: cloudbuild-setup
cloudbuild-setup:
	gcloud artifacts repositories create ${CONTAINER_REGISTRY} --repository-format=docker --location=${REGISTRY_LOCATION} --description="Custom build OpenTelemetry collector container registry"

.PHONY: cloudbuild
cloudbuild:
	gcloud beta builds submit --substitutions=_COLLECTOR_REPO=${CONTAINER_REGISTRY},_COLLECTOR_IMAGE=${IMAGE_NAME}:${IMAGE_VERSION}
