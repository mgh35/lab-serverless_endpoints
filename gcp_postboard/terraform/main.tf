variable "project_id" {
  description = "The project_id of the project where the resources should live"
}

variable "api_version_major" {
  default = "1"
}

variable "api_version_minor" {
  default = "2"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

provider "google" {
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  region  = var.region
  zone    = var.zone
}

// Service account can't create a project without a parent. So for my account creating in the console and importing
// into Terraform with:
//
//resource "random_id" "project" {
//  byte_length = 4
//  prefix      = "postboard-"
//  keepers = {
//    # Locks the ID until we change the version
//    version = "1"
//  }
//}
//
//resource "google_project" "postboard" {
//  name            = "Postboard"
//  project_id      = random_id.project.hex
//  billing_account = var.billing_account
//}
//

resource "google_project_service" "service" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "endpoints.googleapis.com"
  ])

  project             = var.project_id
  service             = each.key
  disable_on_destroy  = false
}

resource "random_id" "source" {
  byte_length = 8
  prefix = "postboard-source-"
  keepers = {
    # Locks the ID until we change the version
    version = "1"
  }
}

resource "google_storage_bucket" "source" {
  project   = var.project_id
  name      = random_id.source.hex
}

data "archive_file" "source" {
  type        = "zip"
  output_path = ".pkg/source.zip"
  source {
    content  = "${file("../postboard/main.py")}"
    filename = "main.py"
  }
}

resource "google_storage_bucket_object" "source" {
  name   = "source.zip"
  bucket = google_storage_bucket.source.name
  source = data.archive_file.source.output_path
  depends_on = [data.archive_file.source]
}

resource "google_cloudfunctions_function" "GET__random_word" {
  project                   = var.project_id
  name                      = "GET__random_word"
  entry_point               = "random_word"
  runtime                   = "python37"
  available_memory_mb       = 128
  timeout                   = 61
  trigger_http              = true
  source_archive_bucket     = google_storage_bucket.source.name
  source_archive_object     = google_storage_bucket_object.source.name
}

//resource "google_cloudfunctions_function_iam_member" "invoker" {
//  # exposes the function globally
//  project        = google_cloudfunctions_function.GET__random_word.project
//  region         = google_cloudfunctions_function.GET__random_word.region
//  cloud_function = google_cloudfunctions_function.GET__random_word.name
//
//  role   = "roles/cloudfunctions.invoker"
//  member = "allUsers"
//}

resource "google_cloud_run_service" "api_gateway" {
  provider = google-beta
  project  = var.project_id
  name     = "api-gateway-v-${var.api_version_major}-${var.api_version_minor}"
  location = var.region
  template {
    spec {
      containers {
        image = "gcr.io/endpoints-release/endpoints-runtime-serverless:2"
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.api_gateway.location
  project     = google_cloud_run_service.api_gateway.project
  service     = google_cloud_run_service.api_gateway.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

locals {
  api_gateway_url = google_cloud_run_service.api_gateway.status[0].url
}

resource "google_endpoints_service" "api" {
  project        = var.project_id
  # Using major and minor version here to work around the problem that APIs can't be recreated after being deleted
  # until purged in 30 days.
//  service_name   = "v-${var.api_version_major}-${var.api_version_minor}.${var.project_id}.appspot.com"
  service_name = replace(local.api_gateway_url, "https://", "")
  openapi_config = templatefile(
    "../openapi-postboard.yaml",
    {
      VERSION_MAJOR = var.api_version_major
      VERSION_MINOR = var.api_version_minor
      HOST = replace(local.api_gateway_url, "https://", "")
      GET__random_word = google_cloudfunctions_function.GET__random_word.https_trigger_url
    }
  )
  depends_on = [google_cloud_run_service.api_gateway]

  # Work-around for circular dependency between the Cloud Endpoints and ESP. See
  # https://github.com/terraform-providers/terraform-provider-google/issues/5528
  provisioner "local-exec" {
    command = "gcloud beta run services update ${google_cloud_run_service.api_gateway.name} --set-env-vars ENDPOINTS_SERVICE_NAME=${self.service_name} --project ${var.project_id} --platform=managed --region=${var.region}"
  }
}

output "project_id" {
  value = var.project_id
}

output "GET__random_word" {
  value = google_cloudfunctions_function.GET__random_word.https_trigger_url
}

output "api_url" {
  value = local.api_gateway_url
}
