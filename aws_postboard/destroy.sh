#!/bin/bash
set -e

cd "$(dirname "$0")"

pushd terraform
  terraform destroy -auto-approve -var api_key=$(terraform output api_key)
popd