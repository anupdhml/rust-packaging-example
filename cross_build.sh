#!/bin/bash
#
# build.sh
#
# Build rust project for various targets
#
# Usage: build.sh TARGET
# Example: build.sh x86_64-unknown-linux-gnu

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

if [[ "$TARGET" == *"alpine-linux-musl"* ]]; then
  # force static binaries for alpine-linux-musl targets (since we are choosing this
  # target specifically to produce working static musl binaries). Static building
  # is the default rustc behavior for musl targets, but alpine disables it by
  # default (via patches to rust).
  echo "Ensuring static builds for alpine-linux-musl targets..."
  export RUSTFLAGS="${RUSTFLAGS} -C target-feature=+crt-static"
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

cross build "${BUILD_ARGS[@]}"

TARGET_BIN="target/${TARGET}/${BUILD_MODE}/${BIN_NAME}"

echo "Successfully built the binary: ${TARGET_BIN}"

# linking check
echo "Printing linking information for the binary..."
file "$TARGET_BIN"
ldd "$TARGET_BIN"
