#!/bin/bash
set -e

cd "$(dirname "$0")"

export FUNCTIONAPP_ID=$(terraform output functionapp_id)
export API_HOST=$(terraform output api_host)
export API_KEY=$(az rest --method post --uri "${FUNCTIONAPP_ID}/host/default/listKeys?api-version=2018-11-01" | jq -r .functionKeys.default)

curl -X GET "https://${API_HOST}/api/random_word?code=${API_KEY}"