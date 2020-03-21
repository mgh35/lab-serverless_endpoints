#!/bin/bash

aws lambda invoke \
    --invocation-type RequestResponse \
    --function-name random_word \
    --region us-east-1 \
    --log-type Tail \
    --profile postboard \
    outputfile.txt \
  | jq .LogResult | sed 's/"//g' | base64 --decode
