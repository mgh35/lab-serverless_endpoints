## Organization

Without a GSuite or Cloud Identity (which seem to be enterprise identity solutions), it looks like no Organization is 
created. So just a flat hierarchy of Projects.

Per Google does, the suggestion with Terraform is manually to create an admin Project and create a Service Account in 
that to be used by Terraform. Inside the Terraform script, it will create a new Project for the application.


## Function

The entry point needs to live in main.py.


Can authorize functions to be called by anyone, eg:
```hcl-terraform
resource "google_cloudfunctions_function_iam_member" "invoker" {
  # exposes the function globally
  project        = google_cloudfunctions_function.GET__random_word.project
  region         = google_cloudfunctions_function.GET__random_word.region
  cloud_function = google_cloudfunctions_function.GET__random_word.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
```
Similarly, functions can call functions given the appropriate IAM like
[here](https://cloud.google.com/functions/docs/securing/authenticating)

## API Gateway

ESP. v1 is NGINX, v2 is Envoy. Need v2 for Cloud Functions.

Configurable proxy. Cloud Endpoints is a wrapper for Service Manager which configures the proxy?__

Cloud Run is service for deploying containers (like Cloud Functions for containers).