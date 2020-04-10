# GCP



## Setup

The main provider is `google`, but some services (Cloud Run, I needed) require `google-beta`:

```hcl-terraform
provider "google" {
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  region  = var.region
  zone    = var.zone
}
```

This is the first hint to suggest this is all still very hot off the press and in flux.

Without a GSuite or Cloud Identity (which seem to be enterprise identity solutions), it looks like no Organization is 
created. So just a flat hierarchy of Projects.

Per Google's docs, the suggestion with Terraform is manually to create an admin Project and create a Service Account in 
that to be used by Terraform. BUT, Terraform can't create a Project without an Organization. So the Project needs to be
manually created. (Ideally that could be imported to Terraform, but then it would be destroyed on destroying the stack
and need to be manually recreated and import. So instead I just pass in the ID.)



## Permissions

GCP has an IAM Role-based setup similar to AWS. I didn't get much into the details.




## Function

Similarly to the others, the code needs to be bundled into a ZIP with all dependencies. Cloud Functions requires that 
the entry point needs to live in main.py.

Each Function is a separate `google_cloudfunctions_function` resource (so could point to different bundles if wanted.

The functions each get their own world-accessible endpoint output by the Resource. Invoking a Function is controlled by 
an IAM. Global authorization can be given like:
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



## Gateway

This is where my GCP Cloud Functions attempt fell down.

The gateway for GCP is Extensible Service Proxy (ESP). The original version was based on NGINX, while they are 
introducing a v2 based on is Envoy. To connect to Cloud Functions, v2 is needed.

ESPv2 is a configurable proxy. It needs to be run on some service, Cloud Run (a managed service to run containers) seems 
to be the recommended choice. This gets its configuration from Cloud Endpoints (a wrapper for Service Manager). Cloud 
Endpoints takes an Open API definition.

The hitch is that there is a circular dependency between these services. GCP's docs recommend starting an ESPv2 with a 
bare image, starting Cloud Endpoints pointing to that, run a script they have written to build a new container layer 
applying the appropriate ESPv2 setup for that Cloud Endpoints instance and saving the image, then restarting ESPv2 with 
that new image. There's no real way to do that with Terraform at the moment (some work-around that half work but fail,
eg, if the ESPv2 is restarted). See the resources for a bunch of discussion around this topic.
 


## Abandoning this

The GCP interface for Cloud Functions, particularly with Terraform, was feeling very beta. This was also notable in the 
relative dearth of documentation (particularly third-party). 

But this API gateway issue was a major sticking point for which there didn't seem any resolution. Abandoning the GCP
investigation here.
