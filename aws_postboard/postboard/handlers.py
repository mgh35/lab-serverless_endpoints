from boto3 import client as boto3_client
import json
import logging
import random

lambda_client = boto3_client('lambda')


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
