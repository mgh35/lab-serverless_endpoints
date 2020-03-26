import boto3
from datetime import datetime
import json
import logging
import os
import random


logging.getLogger().setLevel(
    os.environ.get('LOG_LEVEL', 'INFO').upper()
)

lambda_client = boto3.client('lambda')

postboard = boto3.resource('dynamodb').Table('Postboard')


def random_word(event, context):
    words = ['foo', 'bar', 'blah', 'boop']
    return {
        'isBase64Encoded': False,
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/json'
        },
        'body': random.choice(words)
    }

def call_random_word(event, context):
    try:
        response = json.loads(
            lambda_client.invoke(
                FunctionName='random_word',
                InvocationType='RequestResponse'
            )['Payload'].read()
        )
    except Exception as e:
        logging.exception(e)
        return {
            'isBase64Encoded': False,
            'statusCode': 500,
            'headers': {
                'Content-Type': 'text/plain'
            },
            'body': 'Failed calling random_word'
        }

    return {
        'isBase64Encoded': False,
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/plain'
        },
        'body': response['body']
    }
