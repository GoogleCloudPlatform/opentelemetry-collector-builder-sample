terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.41.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-a"
}


# Create the artifact registry where the custom collector images will be published 
# This does the exact same thing as done by setup-artifact-registry target in the root Makefile 
resource "google_artifact_registry_repository" "my-repo" {
  provider      = google
  location      = var.registry_location
  repository_id = var.container_registry
  description   = "Custom build OpenTelemetry collector container registry"
  format        = "DOCKER"
}

# Create the Google cloud build trigger
resource "google_cloudbuild_trigger" "build_image" {
  description = "Push commit CI to build docker image of opentelemetry custom collector for ${var.repository}"
  filename    = "build/cloudbuild-automation/cloudbuild.yaml"
  github {
    name  = var.repository
    owner = var.owner
    push {
      branch = "^${var.tracked_branch}$"
    }
  }
  name = "build-${var.repository}-image" # name of the build trigger, could be changed to any other string
  tags = [
    "build"
  ]
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

variable "project_id" {
  type = string
}

# Variables used by the generated Google Cloud build trigger

variable "owner" {
    type        = string
    description = "The owner of the GitHub repository for e.g. GoogleCloudPlatform"
}

variable "repository" {
    type        = string
    description = "The repository to create the triggers for e.g. opentelemetry-collector-builder-sample"
}

variable "tracked_branch" {
    type        = string
    description = "The tracked branch of the repository e.g, 'main' or 'master'"
    default     = "main"
}

# Variables used in creating the artifact registry 

variable "container_registry" {
    type        = string
    description = "The name of the artifact repository that needs to be set up."
}

variable "registry_location" {
    type        = string
    description = "The location where artifact repository will be present, for e.g us-central1"
}
