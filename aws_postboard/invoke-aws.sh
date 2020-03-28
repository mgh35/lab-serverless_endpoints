#!/bin/bash

aws lambda invoke \
    --invocation-type RequestResponse \
    --function-name random_word \
    --region us-east-1 \
    --log-type Tail \
    --profile postboard \
    outputfile.txt \
  | jq .LogResult | sed 's/"//g' | base64 --decode


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