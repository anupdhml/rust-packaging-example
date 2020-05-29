#!/bin/bash
#
# package.sh
#
# Package rust project for various targets, across different formats
# Supported formats: tar.gz, deb
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

###############################################################################

function package_archive {
  local archive_name="${BIN_NAME}-${VERSION}-${TARGET}"
  local archive_extension="tar.gz"
  local archive_file="${PACKAGES_DIR}/${archive_name}.${archive_extension}"

  local temp_archive_dir="${TARGET_BUILD_DIR}/${archive_name}"

  if [ -d "${temp_archive_dir}" ]; then
    echo "Temporary archive directory ${temp_archive_dir} already exists. Removing it first"
    rm -rfv "$temp_archive_dir"
  fi
  mkdir -p "$temp_archive_dir"

  echo "Copying files to temporary archive directory: ${temp_archive_dir}"

  # main binary
  mkdir -p "$temp_archive_dir/bin"
  cp -v "$TARGET_BIN" "${temp_archive_dir}/bin"

  # support files
  cp -v README.md LICENSE "${temp_archive_dir}/"
  cp -vR distribution/etc/ "${temp_archive_dir}/"

  echo "Creating package file: ${archive_file}"
  tar cvzf $archive_file -C "$TARGET_BUILD_DIR" "$archive_name"

  # final cleanup
  rm -rf "$temp_archive_dir"

  # for debugging
  #
  #echo "Package info:"
  #echo "Archive size: $(du -hs "$archive_file" | awk '{print $1}')"
  #gzip --list "$archive_file"
  #
  #echo "Package content:"
  #tar --gzip --list --verbose --file="$archive_file"

  echo "Successfully built the package: ${archive_file}"
}


function package_deb {
  # install cargo-deb if not already there (helps us easily build a deb package)
  # see https://github.com/mmstick/cargo-deb
  if ! cargo deb --version > /dev/null 2>&1; then
    echo "Installing cargo-deb..."
    cargo install cargo-deb
  fi

  echo "Creating package file in directory: ${PACKAGES_DIR}"
  # attempt to get the deb file name, but this suppresses error output too
  #local deb_file=$(cargo deb --no-build --output "$PACKAGES_DIR" --deb-version "$VERSION" --target "$TARGET" | tail -n1)
  cargo deb --verbose --no-build --output "$PACKAGES_DIR" --deb-version "$VERSION" --target "$TARGET"

  # final cleanup. directory created by cargo-deb
  rm -rfv target/${TARGET}/debian

  # for debugging
  #
  #echo "Package info:"
  #dpkg --info "$deb_file"
  #
  #echo "Package contents:"
  #dpkg --contents "$deb_file"

  #echo "Successfully built the package: ${deb_file}"
  echo "Successfully built the package."
}

###############################################################################

# TODO control which one to run via new arg to the script?
package_archive
package_deb
