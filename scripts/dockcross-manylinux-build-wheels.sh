#!/bin/bash

# Run this script to build the ITK Python wheel packages for Linux.
#
# Versions can be restricted by passing them a version in as arguments to the
# script. A custom dockcross Docker image can also be specified.
# For example,
#
#   scripts/dockcross-manylinux-build-wheels.sh cp35 manylinux2014-x64:20201015-96d8741

# Generate dockcross scripts
dockcross_image=$2
if test -z "$dockcross_image"; then
  dockcross_image=manylinux2014-x64:20201015-96d8741
fi
dockcross_script=/tmp/dockcross-manylinux
docker run --rm dockcross/${dockcross_image} > $dockcross_script
chmod u+x $dockcross_script

script_dir=$(cd $(dirname $0) || exit 1; pwd)

# Build wheels
pushd $script_dir/..
mkdir -p dist
DOCKER_ARGS="--privileged -v $(pwd)/dist:/work/dist/"
$dockcross_script \
  -a "$DOCKER_ARGS" \
  ./scripts/internal/manylinux-build-wheels.sh "$@"
popd
