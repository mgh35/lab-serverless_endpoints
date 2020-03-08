#!/bin/bash

URL=http://localhost:5000

curl -X POST -H 'Content-Type: application/text' -d 'Hello all' "${URL}/board/rando"
curl -X POST -H 'Content-Type: application/text' -d 'I just want to say a random word: @random_word' "${URL}/board/rando"
curl -X GET "${URL}/board/rando"