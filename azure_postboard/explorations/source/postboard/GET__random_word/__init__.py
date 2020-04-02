import azure.functions as func
import random


def main(req: func.HttpRequest) -> func.HttpResponse:
    words = ['foo', 'bar', 'blah', 'boop']
    return func.HttpResponse(random.choice(words))
