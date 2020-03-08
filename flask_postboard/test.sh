#!/bin/bash
set -e

cd "$(dirname "$0")"

if [ ! -d .venv-test ]; then
  virtualenv .venv-test
fi

source .venv-test/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt

pytest