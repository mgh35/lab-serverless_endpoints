from collections import defaultdict
import pytest
from unittest.mock import patch

import postboard


@pytest.fixture
def client():
    postboard.app.config['TESTING'] = True
    postboard.boards = defaultdict(list)


    with postboard.app.test_client() as client:

        def mocked_postboard_get_self(endpoint: str):
            return client.get(endpoint).data.decode()

        with patch('postboard.get_self', side_effect=mocked_postboard_get_self):
            yield client
