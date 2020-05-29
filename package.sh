#!/bin/bash
#
# package.sh
#
# Package rust project for various targets, across different formats
# Supported formats: archive(tar.gz currently), deb
#
# Meant for use during the final release as part of CI, but can be used for
# local testing too.
#
# Package version is auto-inferred from the project version specified in the
# cargo manifest.
#
# Usage: package.sh TARGET
# Example: package.sh x86_64-unknown-linux-gnu

# exit the script when a command fails
set -o errexit

# catch exit status for piped commands
set -o pipefail

TARGET=$1

if [ -z "$TARGET" ]; then
  echo "Usage: package.sh TARGET"
  exit 1
fi
echo "Packaging for target: ${TARGET}"

BIN_NAME="rust-packaging-example"
TARGET_BUILD_DIR="target/${TARGET}/release" # we always package for release builds
TARGET_BIN="$TARGET_BUILD_DIR/${BIN_NAME}"

# assumes that the build's been done first
if [ ! -f "$TARGET_BIN" ]; then
  echo "Could not find the target binary: ${TARGET_BIN}"
  echo "Was the target build successful (eg: via cross_build.sh)?"
  exit 1
fi
echo "Found the target binary: ${TARGET_BIN}"

# get the package version from cargo manifest (assumption is first instance of
# the regex match pattern here is the package version, which is true for most packages)
VERSION=$(grep --max-count 1 '^version\s*=' Cargo.toml | cut --delimiter '=' -f2 | tr --delete ' ' | tr --delete '"' || true)
#
# accurate determination, but depends on remarshal which won't be availale by default
#VERSION=$(remarshal -i Cargo.toml -of json | jq -r '.package.version')

if [ -z "$VERSION" ]; then
  echo "Error: empty package version. Check the project cargo manifest file."
  exit 1
fi
echo "Determined package version to be: ${VERSION}"

# directory to store the final packaged artifacts
PACKAGES_DIR="packages"
mkdir -p "$PACKAGES_DIR"

# TODO generate man pages and also add them for packaging

echo ""

###############################################################################

# include functions from this file
source "distribution/packaging_functions.sh"

# TODO control which one to run via new arg to the script?
package_archive
echo ""
package_deb
echo ""
echo "All was well."
