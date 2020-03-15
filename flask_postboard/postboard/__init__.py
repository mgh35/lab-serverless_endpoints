from collections import defaultdict
from flask import Flask, jsonify, request, g
from flask_httpauth import HTTPTokenAuth
import random
import requests

boards = defaultdict(list)


def get_self(endpoint: str):
    return requests.get(
        f'http://localhost:5000{endpoint}',
        headers={'Authorization': request.headers['Authorization']}
    ).text


app = Flask(__name__)
auth = HTTPTokenAuth()

tokens = {
    "secret-token-1": "mark",
}


@auth.verify_token
def verify_token(token):
    if token in tokens:
        g.current_user = tokens[token]
        return True
    return False


@app.route('/random_word', methods=['GET'])
@auth.login_required
def get_random_word():
    words = ['foo', 'bar', 'blah', 'boop']
    return random.choice(words)


@app.route('/board/<board_id>', methods=['GET'])
@auth.login_required
def get_board(board_id: str):
    return jsonify(boards[board_id])


@app.route('/board/<board_id>', methods=['POST'])
@auth.login_required
def post_board(board_id: str):
    message = request.data.decode()
    while '@random_word' in message:
        random_word = get_self('/random_word')
        message = message.replace('@random_word', random_word, 1)
    boards[board_id].append(message)
    return message
