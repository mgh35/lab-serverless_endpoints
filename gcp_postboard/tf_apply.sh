#!/bin/bash
set -e

cd "$(dirname "$0")"

if [[ " $* " == *" debug "* ]]
then
  export TF_LOG=DEBUG
fi

ADMIN_PROJECT=$(gcloud projects list | grep postboard-admin- | awk '{print $1}')
export GOOGLE_APPLICATION_CREDENTIALS="/Users/${USER}/.gcp/${ADMIN_PROJECT}-terraform.json"

export TF_VAR_project_id=$(gcloud projects list | grep postboard- | grep -v postboard-admin-  | awk '{print $1}')

cd terraform

if [[ " $* " == *" plan "* ]]
then
  terraform plan
else
  terraform apply -auto-approve
fi
