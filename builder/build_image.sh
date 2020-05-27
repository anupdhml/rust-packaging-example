#!/bin/bash
#
# build_image.sh
#
# Build docker images used for building this rust project
#
# Meant to be run from the same directory as the script
#
# Usage: ./build_image.sh TARGET
# Example: ./build_image.sh x86_64-unknown-linux-gnu

# exit the script when a command fails
set -o errexit

# catch exit status for piped commands
set -o pipefail

TARGET=$1
if [ -z "$TARGET" ]; then
  echo "Usage: build_image.sh TARGET"
  exit 1
fi

DOCKERFILE="Dockerfile.${TARGET}"
if [ ! -f "$DOCKERFILE" ]; then
  echo "A Dockerfile does not exist for the specified target: ${TARGET}"
  exit 1
fi

IMAGE_NAMESPACE="anupdhml"
IMAGE_NAME="example-builder-rust"

RUST_TOOLCHAIN_FILE="../rust-toolchain"
RUST_VERSION=$(<"$RUST_TOOLCHAIN_FILE")

docker build \
  --network host \
  -t "${IMAGE_NAMESPACE}/${IMAGE_NAME}:${TARGET}" \
  -t "${IMAGE_NAMESPACE}/${IMAGE_NAME}:${TARGET}-${RUST_VERSION}" \
  --build-arg RUST_VERSION=${RUST_VERSION} \
  -f ${DOCKERFILE} \
  .
