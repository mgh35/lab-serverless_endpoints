#!/bin/bash
set -e

cd "$(dirname "$0")/terraform"

export API_URL=$(terraform output api_url)

curl --insecure -X GET "http://${API_URL}/v1/random_word"
