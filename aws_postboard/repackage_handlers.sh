#!/bin/bash
set -e

cd "$(dirname "$0")"

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Must specify a version"
  exit 1;
fi

PACKAGED_PATH="${PWD}/.pkg/v${VERSION}.zip"
if [ ! -f "${PACKAGED_PATH}" ]; then
  echo "Package doesn't yet exist"
  exit 1;
fi

pushd postboard
  zip $PACKAGED_PATH -g *.py
popd
