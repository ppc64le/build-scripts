#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : catboost
# Version       : v1.2.7
# Source repo   : https://github.com/catboost/catboost.git
# Tested on     : UBI:9.6 (ppc64le)
# Language      : Python,c,c++
# Ci-Check      : True
# Script License: Apache License Version 2.0
# Maintainer    : Veenious D Geevarghese <Veenious.Geevarghese@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=catboost
PACKAGE_VERSION=${1:-v1.2.7}
PACKAGE_URL=https://github.com/catboost/catboost.git

BUILD_HOME=$(pwd)
WORKDIR=${WORKDIR:-"$BUILD_HOME/catboost_build"}
WORKDIR="$(readlink -f "$WORKDIR")"
REPO_DIR=$WORKDIR/catboost
PKG_DIR=$REPO_DIR/catboost/python-package

PYTHON_VERSION=${PYTHON_VERSION:-3.11.5}
PYTHON_BIN=${PYTHON_BIN:-$(command -v python${PYTHON_VERSION%.*} || true)}
CLANG_VERSION=${CLANG_VERSION:-17.0.6}
CONAN_VERSION=${CONAN_VERSION:-1.62.0}
export PATH=/usr/local/bin:/usr/bin:$PATH

# ----------------------------------------------------------------------------
# Install dependencies
# ----------------------------------------------------------------------------
echo -e "\n[+] Install system dependencies (dnf)\n"

dnf install -y  \
  git \
  gcc gcc-c++ make \
  cmake ninja-build \
  perl \
  wget tar xz unzip zip which findutils \
  openssl-devel libffi-devel zlib-devel xz-devel bzip2-devel sqlite-devel \
  lld \
  nodejs npm \
  libyaml-devel \
  autoconf automake libtool \
  gzip \
  diffutils \
  gcc-gfortran \
  openblas-devel \
  libjpeg-turbo-devel


#Install Python from source
cd "$BUILD_HOME"
if [ ! -d "$BUILD_HOME/Python-${PYTHON_VERSION}" ]; then
    wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
    tar xzf "Python-${PYTHON_VERSION}.tgz"
    rm -rf "Python-${PYTHON_VERSION}.tgz"
fi

cd "Python-${PYTHON_VERSION}"
./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
make -j"$(nproc)"
make altinstall

ln -sf "$(which python3.11)" /usr/bin/python3
ln -sf "$(which pip3.11)" /usr/bin/pip3
python3 -V && pip3 -V


python3 -m pip install -U "pip<24" "setuptools==68.2.2" "wheel==0.41.3" testpath pytest

# ----------------------------------------------------------------------------
#Setup clang
# ----------------------------------------------------------------------------
echo -e "\n[+] Install/Setup clang 17\n"

if command -v clang >/dev/null 2>&1 && clang --version | head -n1 | grep -q "clang version 17"; then
  echo -e "\n[+] Using system clang: $(command -v clang)\n"
else
  cd "$BUILD_HOME"
  LLVM_TARBALL="clang+llvm-${CLANG_VERSION}-powerpc64le-linux-rhel-8.8.tar.xz"
  LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/${LLVM_TARBALL}"

  echo -e "\n[+] Downloading clang/llvm ${CLANG_VERSION} from GitHub releases\n"
  curl -L -o "${LLVM_TARBALL}" "${LLVM_URL}" || { echo -e "\n[!] ERROR: Failed to download ${LLVM_URL}\n" >&2; exit 1; }

  tar -xf "${LLVM_TARBALL}"
  rm -f "${LLVM_TARBALL}"

  LLVM_DIR="clang+llvm-${CLANG_VERSION}-powerpc64le-linux-rhel-8.8"
  [ -d "${LLVM_DIR}" ] || { echo -e "\n[!] ERROR: LLVM directory not found after extract: ${LLVM_DIR}\n" >&2; exit 1; }

  export PATH="$BUILD_HOME/${LLVM_DIR}/bin:$PATH"
  export CC="$BUILD_HOME/${LLVM_DIR}/bin/clang"
  export CXX="$BUILD_HOME/${LLVM_DIR}/bin/clang++"
  export ASM="$BUILD_HOME/${LLVM_DIR}/bin/clang"
fi

clang --version | head -n2

# ----------------------------------------------------------------------------
# Conan 1.x (CatBoost 1.2.7 build scripts expect Conan 1 CLI)
# ----------------------------------------------------------------------------
echo -e "\n[+] Install Conan ${CONAN_VERSION} (Conan 1.x)\n"

python3 -m pip uninstall -y conan || true
python3 -m pip install "conan==${CONAN_VERSION}"
conan --version


# ----------------------------------------------------------------------------
# Clone CatBoost
# ----------------------------------------------------------------------------
echo -e "\n[+] Clone CatBoost repository\n"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [ -d "$REPO_DIR/.git" ]; then
  echo -e "\n[+] Repo exists; fetching updates\n"
  git -C "$REPO_DIR" fetch --all --tags
else
  git clone "$PACKAGE_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"
git checkout "$PACKAGE_VERSION"

# ----------------------------------------------------------------------------
# Patch conanfile.py: disable yasm + ragel tool requirements
# ----------------------------------------------------------------------------
echo -e "\n[+] Patch conanfile.py (disable yasm + ragel tool requirements)\n"

CONANFILE="$REPO_DIR/conanfile.py"
[ -f "$CONANFILE" ] || { echo -e "\n[!] ERROR: conanfile.py not found: $CONANFILE\n" >&2; exit 1; }
sed -i \
  -e 's/^\(\s*\)self\.tool_requires("yasm\/1\.3\.0")/\1#self.tool_requires("yasm\/1.3.0")/g' \
  -e 's/^\(\s*\)self\.tool_requires("ragel\/6\.10")/\1#self.tool_requires("ragel\/6.10")/g' \
  "$CONANFILE"

grep -n 'yasm/1.3.0' "$CONANFILE" || true
grep -n 'ragel/6.10' "$CONANFILE" || true

# ----------------------------------------------------------------------------
# Build ragel from source
# ----------------------------------------------------------------------------

RAGEL_BUILD="$WORKDIR/_ragel_build"
rm -rf "$RAGEL_BUILD"
mkdir -p "$RAGEL_BUILD"
cd "$RAGEL_BUILD"

RAGEL_VER=6.10
RAGEL_TARBALL="ragel-${RAGEL_VER}.tar.gz"
RAGEL_URL="https://www.colm.net/files/ragel/${RAGEL_TARBALL}"

curl -L -o "$RAGEL_TARBALL" "$RAGEL_URL" || { echo -e "\n[!] ERROR: Failed to download ragel tarball\n" >&2; exit 1; }

tar -xzf "$RAGEL_TARBALL"
cd "ragel-${RAGEL_VER}"

./configure --prefix="$RAGEL_BUILD/install"
make -j"$(nproc)"
make install

RAGEL_BIN="$RAGEL_BUILD/install/bin/ragel"
[ -x "$RAGEL_BIN" ] || { echo -e "\n[!] ERROR: ragel binary not found at $RAGEL_BIN\n" >&2; exit 1; }
"$RAGEL_BIN" -v

export PATH="$(dirname "$RAGEL_BIN"):$PATH"


cd "$PKG_DIR"

# Clean python-package artifacts only
rm -rf build dist *.egg-info .eggs || true

# Pre-create ragel location expected by python-package build temp dir.
mkdir -p build/temp.linux-ppc64le-cpython-311/bin
ln -sf "$RAGEL_BIN" build/temp.linux-ppc64le-cpython-311/bin/ragel


ret=0
python3 setup.py bdist_wheel --no-widget || ret=$?
if [ "$ret" -ne 0 ]; then
  echo -e "\n[!] ERROR: Wheel build failed\n" >&2
  exit 1
fi

echo -e "\n[+] Wheel generated in dist/:\n"
ls -lh dist

# ----------------------------------------------------------------------------
# Install wheel
# ----------------------------------------------------------------------------
echo -e "\n[+] Install built wheel\n"

WHEEL_PATH=$(ls -1 "$PKG_DIR/dist"/catboost-1.2.7-*_ppc64le.whl | head -n 1)
[ -f "$WHEEL_PATH" ] || { echo -e "\n[!] ERROR: Wheel not found in dist/\n" >&2; exit 1; }

WHEEL_PATH="$(readlink -f "$WHEEL_PATH")"
python3 -m pip install "$WHEEL_PATH"

# ----------------------------------------------------------------------------
# Run catboost python-package tests
# ----------------------------------------------------------------------------
echo -e "\n[+] Run catboost python-package unit tests (ut/medium)\n"

mkdir -p "$PKG_DIR/test_output"
export CMAKE_SOURCE_DIR="$REPO_DIR"
export CMAKE_BINARY_DIR="$PKG_DIR/build"
export TEST_OUTPUT_DIR="$PKG_DIR/test_output"

cd "$PKG_DIR/ut/medium"
ret=0
python3 -m pytest -v || ret=$?
if [ "$ret" -ne 0 ]; then
  exit 2
fi

# ----------------------------------------------------------------------------
# Conclude
# ----------------------------------------------------------------------------
echo -e "\n[+] Build and test successful!\n"
echo "Wheel located at: $WHEEL_PATH"
exit 0
