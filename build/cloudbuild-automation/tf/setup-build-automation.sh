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

#!/bin/sh
CONTAINER_REGISTRY="otel-collectors" # This can be changed to any name you want
REGISTRY_LOCATION="us-central1" # This can be changed to any region you want
REPOSITORY_NAME="opentelemetry-collector-builder-sample" # Replace it with the name of your repository
REPOSITORY_OWNER="GoogleCloudPlatform" # Replace this with the name of owner of the repository
TRACKED_BRANCH="main" # Replace this with the name of the branch against you wish to add build automation

echo "Running against project ${PROJECT_ID}"

function terraform_init() {
    docker run -v $(pwd):/app -w /app -e "GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}" \
        -v "${GOOGLE_APPLICATION_CREDENTIALS}:${GOOGLE_APPLICATION_CREDENTIALS}:ro" hashicorp/terraform:1.3.3 init
    
    docker run -v $(pwd):/app -e "GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}" \
        -v "${GOOGLE_APPLICATION_CREDENTIALS}:${GOOGLE_APPLICATION_CREDENTIALS}:ro" \
        -w /app hashicorp/terraform:1.3.3 apply \
        -var "project_id=$PROJECT_ID" \
        -var "registry_location=$REGISTRY_LOCATION" \
        -var "container_registry=$CONTAINER_REGISTRY" \
        -var "tracked_branch=$TRACKED_BRANCH" \
        -var "repository=$REPOSITORY_NAME" \
        -var "owner=$REPOSITORY_OWNER" \
        -auto-approve
}

terraform_init
