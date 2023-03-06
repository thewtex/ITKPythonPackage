#!/bin/bash

# Run this script to build the ITK Python wheel packages for Linux.
#
# Versions can be restricted by passing them in as arguments to the script
# For example,
#
#   scripts/dockcross-manylinux-build-wheels.sh cp39
#
# A specialized manylinux image and tag can be used by exporting to
# MANYLINUX_VERSION and IMAGE_TAG before running this script.
# See https://github.com/dockcross/dockcross for available versions and tags.
#
# For example,
#
#   export MANYLINUX_VERSION=2014
#   export IMAGE_TAG=20221205-459c9f0
#   scripts/dockcross-manylinux-build-module-wheels.sh cp39
#

# Handle case where the script directory is not the working directory
script_dir=$(cd $(dirname $0) || exit 1; pwd)

# Set
#
# ITK_PACKAGE_VERSION
# ITKPYTHONPACKAGE_ORG
# ITKPYTHONPACKAGE_TAG
# MANYLINUX_VERSION
# TARGET_ARCH
# IMAGE_TAG
source "${script_dir}/dockcross-manylinux-set-vars.sh"

# Generate dockcross scripts
docker run --rm dockcross/manylinux${MANYLINUX_VERSION}-${TARGET_ARCH}:${IMAGE_TAG} > /tmp/dockcross-manylinux-${TARGET_ARCH}
chmod u+x /tmp/dockcross-manylinux-${TARGET_ARCH}

# Build wheels
pushd $script_dir/..
mkdir -p dist
DOCKER_ARGS="-v $(pwd)/dist:/work/dist/"
DOCKER_ARGS+=" -e MANYLINUX_VERSION -e TARGET_ARCH"
/tmp/dockcross-manylinux-${TARGET_ARCH} \
  -a "$DOCKER_ARGS" \
  ./scripts/internal/manylinux-build-wheels.sh "$@"
popd
