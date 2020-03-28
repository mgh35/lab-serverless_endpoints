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
            'Content-Type': 'text/plain'
        },
        'body': random.choice(words)
    }


def resolve_text(text: str) -> str:
    while '@random_word' in text:
        random_word = json.loads(
            lambda_client.invoke(
                FunctionName='random_word',
                InvocationType='RequestResponse'
            )['Payload'].read()
        )['body']
        text = text.replace('@random_word', random_word, 1)

    return text


def post_board(event, context):
    board_name = event['pathParameters']['boardName']
    message = json.loads(event['body'])
    logging.info(f'message: {message}')
    text = resolve_text(message['text'])

    postboard.update_item(
        Key={
            'BoardName': board_name,
        },
        UpdateExpression="SET Message = list_append(if_not_exists(Message, :empty_list), :text)",
        ExpressionAttributeValues={
            ':empty_list': [],
            ':text': [text],
        },
    )
    return {
        'isBase64Encoded': False,
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'text': text
        })
    }


def get_board(event, context):
    board_name = event['pathParameters']['boardName']
    result = postboard.get_item(
        Key={
            'BoardName': board_name,
        },
    )
    board = result.get('Item', [])
    return {
        'isBase64Encoded': False,
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(board)
    }