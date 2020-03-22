#!/bin/bash

#aws lambda invoke \
#    --invocation-type RequestResponse \
#    --function-name random_word \
#    --region us-east-1 \
#    --log-type Tail \
#    --profile postboard \
#    outputfile.txt \
#  | jq .LogResult | sed 's/"//g' | base64 --decode

curl -H 'Authorization: secret-token-1' -X GET $(terraform output base_url)/api/random_word
curl -H 'Authorization: secret-token-1' -X GET $(terraform output base_url)/api/call_random_word

