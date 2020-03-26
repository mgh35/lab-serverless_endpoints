#!/bin/bash

#aws lambda invoke \
#    --invocation-type RequestResponse \
#    --function-name random_word \
#    --region us-east-1 \
#    --log-type Tail \
#    --profile postboard \
#    outputfile.txt \
#  | jq .LogResult | sed 's/"//g' | base64 --decode

curl -H "Authorization: $(terraform output api_key)" -X GET $(terraform output base_url)/api/random_word
curl -H "Authorization: $(terraform output api_key)" -X GET $(terraform output base_url)/api/call_random_word

curl \
  -H "Authorization: $(terraform output api_key)" \
  -X POST \
  -H 'Content-Type: application/json' \
  --data '{"text": "@random_word to @random_word"}' \
  $(terraform output base_url)/api/board/board1


cat > /tmp/dynamodb_key_conditions.json <<EOF
{
  "BoardName": {
    "AttributeValueList": [
      {"S": "board1"}
    ],
    "ComparisonOperator": "EQ"
  }
}
EOF

aws dynamodb query \
  --profile postboard \
  --region us-east-1 \
  --table-name Postboard \
  --key-conditions file:///tmp/dynamodb_key_conditions.json

