import random


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
