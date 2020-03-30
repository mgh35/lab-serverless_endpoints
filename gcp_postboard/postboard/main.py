import random


def random_word(request):
    words = ['foo', 'bar', 'blah', 'boop']
    return random.choice(words)
