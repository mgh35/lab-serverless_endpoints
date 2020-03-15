from collections import defaultdict, namedtuple
from contextlib import contextmanager
from flask.testing import Client
import pytest
from unittest.mock import patch
import uuid

import postboard

MockedApp = namedtuple('MockedApp', ['client', 'token'])

@pytest.fixture
def mocked_app():
    postboard.app.config['TESTING'] = True
    postboard.boards = defaultdict(list)

    with postboard.app.test_client() as client:
        with auth_token_for_test() as token:

            def mocked_postboard_get_self(endpoint: str):
                from flask import request
                return client.get(endpoint, headers={'Authorization': request.headers['Authorization']}).data.decode()

            with patch('postboard.get_self', side_effect=mocked_postboard_get_self):
                yield MockedApp(client, token)


@contextmanager
def auth_token_for_test():
    token = str(uuid.uuid4())

    import postboard
    old_tokens = postboard.tokens
    try:
        postboard.tokens = {
            token: 'test'
        }
        yield token
    finally:
        postboard.tokens = old_tokens
