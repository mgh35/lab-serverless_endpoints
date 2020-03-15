#!/bin/bash

URL=http://localhost:5000
AUTH='Authorization: Bearer secret-token-1'
curl -X POST -H 'Content-Type: application/text' -H "${AUTH}" -d 'Hello all' "${URL}/board/rando"
curl -X POST -H 'Content-Type: application/text' -H "${AUTH}" -d 'I just want to say a random word: @random_word' "${URL}/board/rando"
curl -X GET -H "${AUTH}" "${URL}/board/rando"