# Content common to manylinux-build-wheels.sh and
# manylinux-build-module-wheels.sh

set -e -x

script_dir=$(cd $(dirname $0) || exit 1; pwd)
# Workaround broken FindPython3 in CMake 3.17
if test -e /usr/share/cmake-3.17/Modules/FindPython/Support.cmake; then
  sudo cp ${script_dir}/Support.cmake /usr/share/cmake-3.17/Modules/FindPython/
fi

# Versions can be restricted by passing them in as arguments to the script
# For example,
# manylinux-build-wheels.sh cp39
if [[ $# -eq 0 ]]; then
  PYBIN=(/opt/python/*/bin)
  PYBINARIES=()
  for version in "${PYBIN[@]}"; do
    if [[ ${version} == *"cp36"* || ${version} == *"cp37"* || ${version} == *"cp38"* || ${version} == *"cp39"* ]]; then
      PYBINARIES+=(${version})
    fi
  done
else
  PYBINARIES=()
  for version in "$@"; do
    PYBINARIES+=(/opt/python/*${version}*/bin)
  done
fi

if file /opt/python/cp39-cp39/bin/python3.9 | grep aarch64 >/dev/null; then
  ARCH=aarch64
else
  # i686 or x86_64 ?
  case $(uname -p) in
      i686)
          ARCH=x86
          ;;
      x86_64)
          ARCH=x64
          ;;
      *)
          die "Unknown architecture $(uname -p)"
          ;;
  esac
fi

# Install prerequirements
if test "${ARCH}" != "x64"; then
  set +e +x
  sudo qemu-binfmt-conf.sh --qemu-suffix=-wrapper.sh
  set -e -x

  skbuild_whl=scikit_build-0.8.0-py2.py3-none-any.whl
  curl -o /tmp/${skbuild_whl} -O https://files.pythonhosted.org/packages/73/c5/20c1e67e63551746b616fcdfc1d406070eacd5a130fc2cc4bd5a7a93e03c/${skbuild_whl}
  wheel_whl=wheel-0.29.0-py2.py3-none-any.whl
  curl -o /tmp/${wheel_whl} -O https://files.pythonhosted.org/packages/8a/e9/8468cd68b582b06ef554be0b96b59f59779627131aad48f8a5bce4b13450/${wheel_whl}
fi
export PATH=/work/tools/doxygen-1.8.11/bin:$PATH
if ! type doxygen > /dev/null 2>&1; then
  mkdir -p /work/tools
    pushd /work/tools > /dev/null 2>&1
    curl https://data.kitware.com/api/v1/file/5c0aa4b18d777f2179dd0a71/download -o doxygen-1.8.11.linux.bin.tar.gz
    tar -xvzf doxygen-1.8.11.linux.bin.tar.gz
  popd > /dev/null 2>&1
fi
if ! type ninja > /dev/null 2>&1; then
  git clone git://github.com/ninja-build/ninja.git
  pushd ninja
  git checkout release
  cmake -Bbuild-cmake -H.
  cmake --build build-cmake
  cp build-cmake/ninja /usr/local/bin/
  popd
fi

echo "Building wheels for $ARCH"
