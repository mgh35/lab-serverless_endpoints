#!/bin/bash
set -e

cd "$(dirname "$0")"

pushd ../terraform
  FUNCTIONAPP_NAME=$(terraform output -json functions | jq -r .name)
popd
echo "Pushing to FunctionApp ${FUNCTIONAPP_NAME}"

pushd ../hello_postboard
  func azure functionapp publish ${FUNCTIONAPP_NAME}
popd
