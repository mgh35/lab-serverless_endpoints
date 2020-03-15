def auth_header(token):
    return {
        'Authorization': f'Bearer {token}'
    }

def test_calls_with_incorrect_auth_token_give_401(mocked_app):
    for endpoint, method in [('/random_word', 'GET'), ('/board/blah', 'GET'), ('/board/blah', 'POST')]:
        if method == 'GET':
            response = mocked_app.client.get(endpoint)
        elif method == 'POST':
            response = mocked_app.client.post(endpoint, json={})
        else:
            assert False, 'Invalid method'

        assert response.status_code == 401, f'Endpoint {endpoint} [{method}] should require authorization'


def test_random_words_returns_a_random_word(mocked_app):
    words = set()
    for i in range(10):
        response = mocked_app.client.get('/random_word', headers=auth_header(mocked_app.token))
        assert response.status_code == 200
        words.add(response.data.decode())

    assert len(words) > 1
    assert words <= {'foo', 'bar', 'blah', 'boop'}


def test_get_from_new_board_returns_empty_list(mocked_app):
    assert mocked_app.client.get('/board/blah', headers=auth_header(mocked_app.token)).json == []


def test_messages_posted_to_empty_board_appear(mocked_app):
    assert mocked_app.client.get('/board/blah', headers=auth_header(mocked_app.token)).json == []
    msg = 'Hello, board!'
    assert mocked_app.client.post('/board/blah', data=msg, headers=auth_header(mocked_app.token)).data.decode() == msg
    assert mocked_app.client.get('board/blah', headers=auth_header(mocked_app.token)).json == [msg]


def test_messages_posted_to_empty_board_appear_in_another_test_session(mocked_app):
    assert mocked_app.client.get('/board/blah', headers=auth_header(mocked_app.token)).json == []
    msg = 'Hello, boardy!'
    assert mocked_app.client.post('/board/blah', data=msg, headers=auth_header(mocked_app.token)).data.decode() == msg
    assert mocked_app.client.get('board/blah', headers=auth_header(mocked_app.token)).json == [msg]


def test_random_word_markup_gets_replaced(mocked_app):
    assert mocked_app.client.get('/board/blah', headers=auth_header(mocked_app.token)).json == []
    msg = 'Hello, @random_word!'
    posted_msg = mocked_app.client.post('/board/blah', data=msg, headers=auth_header(mocked_app.token)).data.decode()
    assert posted_msg in [f'Hello, {word}!' for word in ['foo', 'bar', 'blah', 'boop']]
    assert mocked_app.client.get('board/blah', headers=auth_header(mocked_app.token)).json == [posted_msg]
