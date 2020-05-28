#!/bin/bash
#
# build.sh
#
# Build rust project for various targets and generate archive for distribution
#
# Usage: build.sh TARGET [VERSION]
# Example: build.sh x86_64-unknown-linux-gnu 0.8.0

# exit the script when a command fails
set -o errexit

# catch exit status for piped commands
set -o pipefail

TARGET=$1

if [ -z "$TARGET" ]; then
  echo "Usage: build.sh TARGET"
  exit 1
fi

if [ "$RUST_PACKAGING_EXAMPLE_MODE" = "debug" ]; then
  BUILD_MODE=debug
else
  BUILD_MODE=release
fi

BIN_NAME="rust-packaging-example"

###############################################################################

echo "Building for target: ${TARGET}..."

BUILD_ARGS=("--target" "$TARGET")
if [ "$BUILD_MODE" == "release" ]; then
  BUILD_ARGS+=("--release")
fi

# install cross if not already there (helps us build easily across various targets)
# see https://github.com/rust-embedded/cross
#
# currently need to install it from a personal fork for builds to work against custom targets
# (eg: x86_64-alpine-linux-musl which we use for generating working musl binaries right now)
if ! command -v cross > /dev/null; then
  echo "Installing cross..."
  cargo install --git https://github.com/anupdhml/cross.git --branch custom_target_fixes
fi

# TODO enable at the end?
cross build "${BUILD_ARGS[@]}"

# check

TARGET_BUILD_DIR="target/${TARGET}/${BUILD_MODE}"
TARGET_BIN="$TARGET_BUILD_DIR/${BIN_NAME}"

echo "Printing linking information for the binary..."
file "$TARGET_BIN"
ldd "$TARGET_BIN"

###############################################################################

echo "Packaging for target: ${TARGET}"

LATEST_COMMIT_HASH=$(git rev-parse --short HEAD)

# if no version argument is provided to the script, use latest commit hash
# TODO document this in script usage
VERSION=${2-${LATEST_COMMIT_HASH}}

ARCHIVE_NAME="${BIN_NAME}-${VERSION}-${TARGET}"
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

echo "Creating archive file with name: ${ARCHIVE_NAME}"
tar cvzf "${ARCHIVE_NAME}.tar.gz" -C "$TARGET_BUILD_DIR" "$ARCHIVE_NAME"

# final cleanup
rm -rf "$TEMP_ARCHIVE_DIR"

echo "Done!"
