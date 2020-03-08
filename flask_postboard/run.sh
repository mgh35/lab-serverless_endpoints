#!/bin/bash
set -e

cd "$(dirname "$0")"

if [ ! -d .venv ]; then
  virtualenv .venv
fi

source .venv/bin/activate
pip install -r requirements.txt

export FLASK_DEBUG=1
python app.py