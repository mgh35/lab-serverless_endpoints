#!/bin/bash
set -e

cd "$(dirname "$0")"

./repackage_handlers.sh $1

if [[ ! " $* " =~ " --new-key " ]]; then
  pushd terraform
    API_KEY=$(terraform output api_key)
  popd
fi
if [ -z $API_KEY ]; then
  echo "Generating new API_KEY"
  API_KEY=$(uuidgen)
fi

pushd terraform
  terraform apply -auto-approve -var api_key="${API_KEY}"
popd