#!/bin/bash
set -e

cd "$(dirname "$0")"

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Must specify a version"
  exit 1;
fi

PACKAGED_PATH="${PWD}/.pkg/v${VERSION}.zip"
if [ -f "${PACKAGED_PATH}" ]; then
  echo "Package already exists"
  exit 1;
fi

echo "Building package ${VERSION}"

WORKING_DIR=$(mktemp -d)
cp postboard/*.py $WORKING_DIR
pip install -t $WORKING_DIR -r requirements.txt
pushd $WORKING_DIR
  zip $PACKAGED_PATH *
popd
rm -rf $WORKING_DIR
