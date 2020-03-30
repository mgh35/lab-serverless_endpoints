#!/bin/bash

#gcloud init
#gcloud config set run/region us-central1

PROJECT=$(gcloud config list | grep project | sed 's/^project = //')


ESP_SERVICE_NAME=test-postboard-esp
ESP_SERVICE_DEPLOY_INIT=$(gcloud run deploy $ESP_SERVICE_NAME \
    --image="gcr.io/endpoints-release/endpoints-runtime-serverless:2" \
    --allow-unauthenticated \
    --platform managed \
    |& tee /dev/stderr
)
ESP_SERVICE_URL=$(echo $ESP_SERVICE_DEPLOY_INIT | tail -1 | sed 's/^.* of traffic at //')
ESP_SERVICE_HOST=$(echo $ESP_SERVICE_URL | sed 's/https:\/\///')

ESP_API_DEPLOY=$(gcloud endpoints services deploy openapi-postboard.yaml |& tee /dev/stderr)
ESP_API_CONFIG_ID=$(echo $ESP_API_DEPLOY | tail -3 | head -n 1 | sed 's/^Service Configuration \[\([^]]*\)\].*$/\1/')

if [ ! -f gcloud_build_image ]; then
  wget https://raw.githubusercontent.com/GoogleCloudPlatform/esp-v2/master/docker/serverless/gcloud_build_image
  chmod +x gcloud_build_image
fi
ESP_SERVICE_IMAGE_BUILD=$(./gcloud_build_image -s $ESP_SERVICE_HOST -c $ESP_API_CONFIG_ID -p $PROJECT |& tee /dev/stderr)
ESP_SERVICE_IMAGE=$(echo $ESP_SERVICE_IMAGE_BUILD | tail -1 | awk '{print $5}')

ESP_SERVICE_DEPLOY=$(gcloud run deploy $ESP_SERVICE_NAME \
    --image=$ESP_SERVICE_IMAGE \
    --allow-unauthenticated \
    --platform managed \
    |& tee /dev/stderr
)
API_BASE_URL=$(echo $ESP_SERVICE_DEPLOY | tail -1 | sed 's/^.* of traffic at //')


#gcloud functions add-iam-policy-binding GET__random_word \
#   --member "serviceAccount:546800080477-compute@developer.gserviceaccount.com" \
#   --role "roles/cloudfunctions.invoker"


curl -X GET "${API_BASE_URL}/random_word?key=${API_KEY}"