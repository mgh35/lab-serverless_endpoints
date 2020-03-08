
def test_random_words_returns_a_random_word(client):
    words = set()
    for i in range(10):
        response = client.get('/random_word')
        assert response.status_code == 200
        words.add(response.data.decode())

    assert len(words) > 1
    assert words <= {'foo', 'bar', 'blah', 'boop'}


def test_get_from_new_board_returns_empty_list(client):
    assert client.get('/board/blah').json == []


def test_messages_posted_to_empty_board_appear(client):
    assert client.get('/board/blah').json == []
    msg = 'Hello, board!'
    assert client.post('/board/blah', data=msg).data.decode() == msg
    assert client.get('board/blah').json == [msg]


def test_messages_posted_to_empty_board_appear_in_another_test_session(client):
    assert client.get('/board/blah').json == []
    msg = 'Hello, boardy!'
    assert client.post('/board/blah', data=msg).data.decode() == msg
    assert client.get('board/blah').json == [msg]


def test_random_word_markup_gets_replaced(client):
    assert client.get('/board/blah').json == []
    msg = 'Hello, @random_word!'
    posted_msg = client.post('/board/blah', data=msg).data.decode()
    assert posted_msg in [f'Hello, {word}!' for word in ['foo', 'bar', 'blah', 'boop']]
    assert client.get('board/blah').json == [posted_msg]
