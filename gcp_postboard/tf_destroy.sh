#!/bin/bash
set -e

cd "$(dirname "$0")"

ADMIN_PROJECT=$(gcloud projects list | grep postboard-admin- | awk '{print $1}')
export GOOGLE_APPLICATION_CREDENTIALS="/Users/${USER}/.gcp/${ADMIN_PROJECT}-terraform.json"

export TF_VAR_project_id=$(gcloud projects list | grep postboard- | grep -v postboard-admin-  | awk '{print $1}')

cd terraform

terraform destroy -auto-approve