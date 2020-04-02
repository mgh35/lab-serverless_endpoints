#!/bin/bash
set -e

cd "$(dirname "$0")"

if [[ " $* " == *" debug "* ]]
then
  export TF_LOG=DEBUG
fi

if [[ " $* " == *" plan "* ]]
then
  terraform plan
else
  terraform apply -auto-approve
fi