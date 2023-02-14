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

IMAGE_NAME=otelcol-custom
IMAGE_VERSION=latest

CONTAINER_REGISTRY=otel-collectors
REGISTRY_LOCATION=us-central1

.PHONY: setup-artifact-registry
setup-artifact-registry:
	gcloud artifacts repositories create ${CONTAINER_REGISTRY} --repository-format=docker --location=${REGISTRY_LOCATION} --description="Custom build OpenTelemetry collector container registry"

.PHONY: generate-toc
generate-toc:
	python3 -m pip install markdown-toc
	find . -name 'README.md' -exec markdown-toc -t github {} \;
