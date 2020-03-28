#!/bin/bash

curl -H "Authorization: $(terraform output api_key)" -X GET $(terraform output base_url)/api/random_word

curl \
  -H "Authorization: $(terraform output api_key)" \
  -X POST \
  -H 'Content-Type: application/json' \
  --data '{"text": "@random_word to @random_word"}' \
  $(terraform output base_url)/api/board/board1

curl \
  -H "Authorization: $(terraform output api_key)" \
  -X GET \
  $(terraform output base_url)/api/board/board1


