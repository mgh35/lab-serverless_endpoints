# AWS



## Setup

Support for AWS in Terraform is naturally provided by the `aws` provider:

```hcl-terraform
provider "aws" {
  profile    = "postboard"
  region     = "us-east-1"
}
```

You will want to perform your actions as a user separate from your root login. This user will need the appropriate perms 
to create the resources / etc - AdministratorAccess is an easy if not very secure way to get that up quickly. You will
want to create this user in the IAM page of the AWS Console, and make sure to get the Access Key and Secret Key. You can 
save those creds to a profile with AWS CLI (`aws configure`), and any future calls just need to specify the profile.



## Permissions

Permissions are controlled through IAM Roles. Each Role has a corresponding Policy, describing what Authorizations it
has, and an Assume Policy, describing what authorizations are needed to assume that Role.

Roles are created like:

```hcl-terraform
resource "aws_iam_role" "role_name" {
  name = "role_name"
 
  assume_role_policy = ...
}

resource "aws_iam_role_policy" "policy_name" {
  name = "policy_name"
  role = aws_iam_role.role_name.id

  policy = ...
}
```

where the policy follows AWS's JSON Policy format (either in heredoc format inline or build using a reference to a
Terraform policy_document).

An policy JSON looks like:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```



## Database

DynamoDB is the main AWS key-value store. It supports a bipartite key with Hash Key driving it's partition placement and 
an optional second level sort key within that. Each one can be multi-part. The value is then a dictionary of typed 
values.

Here, we just need a simple single-part Partition Key corresponding to the BoardName. Provisioning a DynamoDB table
in Terraform is straightforward:

```hcl-terraform
resource "aws_dynamodb_table" "postboard" {
  name = "Postboard"
  billing_mode = "PROVISIONED"
  read_capacity = 5
  write_capacity = 5
  hash_key = "BoardName"

  attribute {
    name = "BoardName"
    type = "S"
  }
}
``` 

The `billing_mode` allows options to pay for either a fixed maximum throughput or whether to pay per the used 
throughput.

The only peculiarity is the typing of the values. A STRING value, eg, appears as:

```json
{
  "Item": {
    "MyKey": {"S": "my string value"}
  }
}
```

(The latest version of the boto3 library in Python manages this behind the scenes and allows using simple Python types.)



## Functions

This is the meat of the Lambda. 

First, the code needs to be bundled in a single zip with all dependencies. For Python, build a directory with the source
files and use `pip install -t` in that directory to install any dependencies locally. That directory can then just be 
zipped up.

Then create the Lambda resource. That zip can either be referenced from an S3, or Terraform can be passed the local 
file directly:

```hcl-terraform
resource "aws_lambda_function" "random_word" {
  role             = aws_iam_role.lambda.arn
  handler          = "handlers.random_word"
  runtime          = "python3.6"
  filename         = var.file
  function_name    = "random_word"
  source_code_hash = "${filebase64sha256(var.file)}--${aws_iam_role.lambda.arn}"

  environment {
    variables = {
      LOG_LEVEL = var.log_level
    }
  }
}
```

One fiddly point proved to be Lambdas failing to authorize after changes were made. This was resolved in some 
Terraform GitHub issues by adding the IAM roll ARN to the source_code_hash. Turns out, without that it wasn't properly
updating on changes.

The Lambda's IAM role needs the appropriate permissions. For simplicity, I've used here a single policy across all
Lambdas. These want to be able call other Lambdas, create logs in Cloudwatch, and operate on the DynamoDB table:

```json
{
  "Version": "2012-10-17",
  "Statement": [
     {
        "Sid": "AllowCallingOtherLambda",
        "Effect": "Allow",
        "Action": [
            "lambda:InvokeFunction"
        ],
        "Resource": "*"
    },
    {
      "Sid": "TurnOnCloudWatchLogging",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Sid": "AllowDynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "${aws_dynamodb_table.postboard.arn}"
    }
  ]
}
```

Once the function is up, you can run them using the AWS API:

```shell script
aws lambda invoke \
    --invocation-type RequestResponse \
    --function-name random_word \
    --region us-east-1 \
    --log-type Tail \
    --profile postboard \
    outputfile.txt \
  | jq .LogResult | sed 's/"//g' | base64 --decode
```


## Gateway

This is the service that connects external requests to the Lambda functions. 

Here, using it to connect HTTP requests. For this, we want an API Gateway and with a REST API: 

```hcl-terraform
resource "aws_api_gateway_account" "postboard" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_rest_api" "postboard" {
  name        = "Postboard"
  description = "Postboard App"
}
```

Authorization is specified by an `aws_api_gateway_authorizer`. Cognito is the likely candidate, but for simplicity here
I've just used the (seemingly legacy) lambda authorizer. This allows defining a Lambda that will be passed the request 
return a Policy to apply to the User. AWS Labs provide templates for the Policy creation across various languages. I've 
taken that here and just validated the Authorization Header against a static value specified at cluster deployment.

There are 2 key concepts in the REST API:

### Resource Hierarchy

This is where the API is defined.

This is a hierarchy consisting of:
* nested `aws_api_gateway_resource`s specifying the URL path
* one or more `aws_api_gateway_method`s specifying the HTTP methods allowed
* an `aws_api_gateway_integration` specifying how the specified method is mapped to a backend call

Each Resource maps to a URL path part. So you nest them as you go down the URL path tree. These can also be variable 
(using curly brace syntax) which get passed through the Integration into the Context with the appropriate 
`request_parameters` setting in the Method. (There's also an option to capture the full subtree with `+` - like 
`{path+}`.) Note that the root path `/` is handled slightly differently and needs to use the root_resource_id from the
`aws_api_gateway_rest_api`.

Each Integration is mapped to an authorizer. This controls access from outside to the endpoint.

Note that permissions also need to be set up to allow API Gateway to call you're Lambda. There's an 
`aws_lambda_permission` resource in Terraform to set that.

Also note that AWS Lambda requires it be called as a POST request. So the Integration needs to specify the 
`integration_http_method = "POST"`.

### Deployment

This is an actual instantiation of the Resources. So doesn't do much but stand in for a concrete instance of the API.

So, for example, you can create different deployments for dev / test / prod. Or however you want to structure it.

One subtlety is the `depends_on` parameter. The issue this address is that the Deployment is intentionally separate from 
the API so won't get updated if the API is updated. This is intended as this could be desired (so that a prod 
Deployment, eg, won't pick up changes made for test if you were running them out of the same place). The `depends_on` 
allows you to specify the dependency explicitly and so have the Deployment update when the API does.



## Logging

CloudWatch is the AWS service hosting logs.

Note in the previous section we specified a `cloudwatch_role_arn` to the aws_api_gateway_account. To turn on CloudWatch,
you need to create a Role with the appropriate perms to create logs and then specify that at the account level.

To get logging of Lambdas, their Role also wants to include perms to write to CloudWatch.



## Lambda API

The API Gateways calls Lambdas passing an Event and a Context.

In the Python API, the Event is a simple dictionary to which the API Gateway adds much of information about the request. 
For example, where there is a path parameter this is included under the `pathParameters` as a dictionary of the 
parameter name -> value. The Context is a typed object that provides, surprisingly, context about the call. Eg, you 
could find the Cognito authorized user here.

The return value of the Lambda has to conform to:

```python
{
    'isBase64Encoded': False,
    'statusCode': 200,
    'headers': {
        'Content-Type': 'text/plain'
    },
    'body': random.choice(words)
}
```



## Calling AWS Services from a Lambda

There's an AWS SDK to call other AWS services (including other Lambdas) from a Lambda. For Python, this is the `boto3`
package.

Calling another Lambda, for example, involves:

```python
import boto3
import json

lambda_client = boto3.client('lambda')

json.loads(
    lambda_client.invoke(
        FunctionName='random_word',
        InvocationType='RequestResponse'
    )['Payload'].read()
)
```

(and the calling Lambda must have a Policy allowing it to perform whatever it's trying to do).
