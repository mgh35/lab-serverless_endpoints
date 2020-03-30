#!/bin/bash
set -e

#ADMIN_PROJECT="postboard-admin-$(cat /dev/urandom | base64 | tr -cd '0-9a-z' | head -c 8)"
#BILLING_ACCOUNT=$(gcloud beta billing accounts list | tail -1 | awk '{print $1}')


if [ -z ${ADMIN_PROJECT} ]; then
  echo "Must specify ADMIN_PROJECT"
  exit 1
fi

if [ -z ${BILLING_ACCOUNT} ]; then
  echo "Must specify BILLING_ACCOUNT"
  exit 1
fi

gcloud projects create ${ADMIN_PROJECT} --name "Postboard Admin"
gcloud beta billing projects link ${ADMIN_PROJECT} --billing-account ${BILLING_ACCOUNT}

ADMIN_USER=terraform
ADMIN_CREDS=/Users/${USER}/.gcp/${ADMIN_PROJECT}-${ADMIN_USER}.json
gcloud iam service-accounts create ${ADMIN_USER} \
  --project ${ADMIN_PROJECT} \
  --display-name "Terraform Admin"
gcloud iam service-accounts keys create ${ADMIN_CREDS} \
  --iam-account ${ADMIN_USER}@${ADMIN_PROJECT}.iam.gserviceaccount.com

