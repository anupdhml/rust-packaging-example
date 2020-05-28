#!/bin/bash
#
# package.sh
#
# Package rust project for various targets, across different formats
#
# Supported package formats:
#   * tar.gz
#
# Usage: package.sh TARGET [VERSION]
# Example: package.sh x86_64-unknown-linux-gnu 0.8.0

# exit the script when a command fails
set -o errexit

# catch exit status for piped commands
set -o pipefail

TARGET=$1

if [ -z "$TARGET" ]; then
  echo "Usage: package.sh TARGET"
  exit 1
fi

BIN_NAME="rust-packaging-example"
TARGET_BUILD_DIR="target/${TARGET}/release" # we always package for release builds
TARGET_BIN="$TARGET_BUILD_DIR/${BIN_NAME}"

# assumes that the build's been done first
if [ ! -f "$TARGET_BIN" ]; then
  echo "Could not find the target binary: ${TARGET_BIN}"
  echo "Was the target build successful (eg: via cross_build.sh)?"
  exit 1
fi

###############################################################################

echo "Packaging for target: ${TARGET}"

# directory to store the final packaged artifacts
PACKAGES_DIR="packages"
mkdir -p "$PACKAGES_DIR"

# if no version argument is provided to the script, use latest commit hash
# TODO document this in script usage
LATEST_COMMIT_HASH=$(git rev-parse --short HEAD)
VERSION=${2-${LATEST_COMMIT_HASH}}

ARCHIVE_NAME="${BIN_NAME}-${VERSION}-${TARGET}"
ARCHIVE_EXTENSION="tar.gz"
ARCHIVE_FILE="${PACKAGES_DIR}/${ARCHIVE_NAME}.${ARCHIVE_EXTENSION}"

TEMP_ARCHIVE_DIR="${TARGET_BUILD_DIR}/${ARCHIVE_NAME}"

if [ -d "${TEMP_ARCHIVE_DIR}" ]; then
  echo "Temporary archive directory ${TEMP_ARCHIVE_DIR} already exists. Removing it first"
  rm -rfv "$TEMP_ARCHIVE_DIR"
fi
mkdir -p "$TEMP_ARCHIVE_DIR"

echo "Copying files to temporary archive directory: ${TEMP_ARCHIVE_DIR}"

# main binary
mkdir -p "$TEMP_ARCHIVE_DIR/bin"
cp -v "$TARGET_BIN" "${TEMP_ARCHIVE_DIR}/bin"

# support files
cp -v README.md LICENSE "${TEMP_ARCHIVE_DIR}/"
cp -vR distribution/etc/ "${TEMP_ARCHIVE_DIR}/"

echo "Creating archive file: ${ARCHIVE_FILE}"
tar cvzf $ARCHIVE_FILE -C "$TARGET_BUILD_DIR" "$ARCHIVE_NAME"

# final cleanup
rm -rf "$TEMP_ARCHIVE_DIR"

echo "Successfully built the package: ${ARCHIVE_FILE}"
